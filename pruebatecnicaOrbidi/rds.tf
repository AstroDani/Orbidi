resource "aws_rds_cluster" "main" {
  cluster_identifier = "orbidi-cluster"
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = "15.7"
  database_name      = "test"
  master_username    = "orbidi"
  master_password    = random_password.user_password.result
  storage_encrypted  = true
  db_subnet_group_name = aws_db_subnet_group.main.name
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.rds.id]

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0
    seconds_until_auto_pause = 3600
  }
}

resource "aws_rds_cluster_instance" "main" {
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version
  db_subnet_group_name = aws_db_subnet_group.main.name
}

#CONEXION SUBNETS
resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = aws_subnet.private[*].id
}

#PASWORD

resource "random_password" "user_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_ssm_parameter" "rds_password" {
  name = "rds-password"
  type = "SecureString"
  value = aws_rds_cluster.main.master_password
}