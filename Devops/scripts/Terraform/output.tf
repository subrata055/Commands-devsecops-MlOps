output "cluster_id" {
  value = aws_eks_cluster.Mega-Project.id
}

output "node_group_id" {
  value = aws_eks_node_group.Mega-Project.id
}

output "vpc_id" {
  value = aws_vpc.Mega-Project_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.Mega-Project_subnet[*].id
}
