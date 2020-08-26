resource "aws_efs_file_system" "filesystem" {
  tags = { Name = "${var.cluster_name}-efs" }

}

resource "aws_efs_access_point" "solr" {
  file_system_id = aws_efs_file_system.filesystem.id
  posix_user {
    gid = 8983
    uid = 8983
  }

  root_directory {
    path = "/efs-ap-${var.cluster_name}-solr"
    creation_info {
      owner_gid   = 8983
      owner_uid   = 8983
      permissions = 755
    }
  }

}
resource "aws_efs_access_point" "psql" {
  file_system_id = aws_efs_file_system.filesystem.id
  posix_user {
    gid = 999
    uid = 999
  }

  root_directory {
    path = "/efs-ap-${var.cluster_name}-psql"
    creation_info {
      owner_gid   = 999
      owner_uid   = 999
      permissions = 755
    }
  }

}
