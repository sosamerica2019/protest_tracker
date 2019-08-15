Aws.config.update({
  region: 'eu-central-1',
  credentials: Aws::Credentials.new(ENV['aws_access_key_id'], ENV['aws_secret_access_key']),
})

S3_BUCKET = Aws::S3::Resource.new.bucket(ENV['aws_bucket'])