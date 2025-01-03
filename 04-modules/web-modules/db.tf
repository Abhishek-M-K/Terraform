resource "aws_db_instance" "sample_db" {
    db_name = "sampledbforfun"
    instance_class = "db.t3.micro"
    allocated_storage = 10 # 10 GB
    storage_type = "standard"
    engine = "mysql"
    engine_version = "5.7"
    username = "admin"
    password = var.db_password
    skip_final_snapshot = true # Don't take a snapshot when the instance is deleted (Snapshot is a backup of the database)
}