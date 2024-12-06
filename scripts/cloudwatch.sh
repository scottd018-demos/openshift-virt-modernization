#!/usr/bin/env sh

SCRATCH_DIR="tmp"

AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-`aws sts get-caller-identity --query 'Account' --output text`}"
AWS_OIDC_PROVIDER="$(oc get authentication.config.openshift.io cluster -o json \
| jq -r .spec.serviceAccountIssuer| sed -e "s/^https:\/\///")"
AWS_POLICY_NAME="dscott-cloudwatch"
AWS_ROLE_NAME="dscott-cloudwatch"

# this is the service account that will authenticate against aws for the role created
OPENSHIFT_SERVICE_ACCOUNT='cloudwatch'
OPENSHIFT_SERVICE_ACCOUNT_NAMESPACE='openshift-logging'

mkdir -p $SCRATCH_DIR

# policy
cat <<EOF > $SCRATCH_DIR/cloudwatch-policy.json
{
"Version": "2012-10-17",
"Statement": [
    {
    "Effect": "Allow",
    "Action": [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:PutRetentionPolicy"
    ],
    "Resource": "arn:aws:logs:${AWS_REGION}:${AWS_ACCOUNT_ID}:*"
    }
  ]
}
EOF

# trust policy
cat <<EOF > $SCRATCH_DIR/cloudwatch-trust-policy.json
{
   "Version": "2012-10-17",
   "Statement": [
   {
   "Effect": "Allow",
   "Condition": {
     "StringEquals" : {
       "${AWS_OIDC_PROVIDER}:sub": ["system:serviceaccount:${OPENSHIFT_SERVICE_ACCOUNT_NAMESPACE}:${OPENSHIFT_SERVICE_ACCOUNT}"]
      }
    },
    "Principal": {
       "Federated": "arn:aws:iam:::oidc-provider/${AWS_OIDC_PROVIDER}"
    },
    "Action": "sts:AssumeRoleWithWebIdentity"
    }
    ]
}
EOF

POLICY=$(aws iam create-policy --policy-name "${AWS_POLICY_NAME}" \
   --policy-document file://$SCRATCH_DIR/cloudwatch-policy.json \
   --query 'Policy.Arn' --output text)
echo "created policy: $POLICY"

ROLE=$(aws iam create-role \
  --role-name "${AWS_ROLE_NAME}" \
  --assume-role-policy-document file://$SCRATCH_DIR/cloudwatch-trust-policy.json \
  --query "Role.Arn" --output text)
echo "created role: $ROLE"

aws iam attach-role-policy \
   --role-name "${AWS_ROLE_NAME}" \
   --policy-arn $POLICY

rm -rf $SCRATCH_DIR
