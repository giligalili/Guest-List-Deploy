# Security Module - Creates security groups and rules

# Security Group for EKS Cluster
resource "aws_security_group" "cluster" {
  name_prefix = "${var.cluster_name}-cluster-"
  vpc_id      = var.vpc_id
  description = "Security group for EKS cluster control plane"

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-cluster-sg"
  })
}

# Security Group for EKS Worker Nodes
resource "aws_security_group" "nodes" {
  name_prefix = "${var.cluster_name}-nodes-"
  vpc_id      = var.vpc_id
  description = "Security group for EKS worker nodes"

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-nodes-sg"
  })
}

# Security Group for Application Load Balancer
resource "aws_security_group" "alb" {
  name_prefix = "${var.cluster_name}-alb-"
  vpc_id      = var.vpc_id
  description = "Security group for Application Load Balancer"

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-alb-sg"
  })
}

# Cluster Security Group Rules
resource "aws_security_group_rule" "cluster_ingress_node_https" {
  description              = "Allow nodes to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.nodes.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_egress_internet" {
  description       = "Allow cluster egress access to the Internet"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.cluster.id
  cidr_blocks       = ["0.0.0.0/0"]
  to_port           = 0
  type              = "egress"
}

# Node Security Group Rules
resource "aws_security_group_rule" "nodes_ingress_self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.nodes.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "nodes_ingress_cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.cluster.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "nodes_ingress_cluster_https" {
  description              = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.cluster.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "nodes_ingress_alb" {
  description              = "Allow ALB to communicate with worker nodes"
  from_port                = 0
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.alb.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "nodes_egress_internet" {
  description       = "Allow nodes egress access to the Internet"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.nodes.id
  cidr_blocks       = ["0.0.0.0/0"]
  to_port           = 0
  type              = "egress"
}

# ALB Security Group Rules
resource "aws_security_group_rule" "alb_ingress_http" {
  description       = "Allow HTTP traffic from internet"
  from_port         = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
  to_port           = 80
  type              = "ingress"
}

resource "aws_security_group_rule" "alb_ingress_https" {
  description       = "Allow HTTPS traffic from internet"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group_rule" "alb_ingress_app_port" {
  description       = "Allow application port traffic from internet"
  from_port         = var.app_port
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
  to_port           = var.app_port
  type              = "ingress"
}

resource "aws_security_group_rule" "alb_egress_nodes" {
  description              = "Allow ALB to communicate with worker nodes"
  from_port                = 0
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.nodes.id
  to_port                  = 65535
  type                     = "egress"
}

# Network ACLs for additional security (optional)
resource "aws_network_acl" "main" {
  vpc_id     = var.vpc_id
  subnet_ids = concat(var.public_subnet_ids, var.private_subnet_ids)

  # Allow inbound HTTP
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Allow inbound HTTPS
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow inbound SSH
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 22
    to_port    = 22
  }

  # Allow inbound ephemeral ports
  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow all outbound traffic
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-nacl"
  })
}
