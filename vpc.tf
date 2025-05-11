resource "aws_default_vpc" "vpcrenegociacao-dividas" {
  tags = {
    Name = "Default VPC to Tech Challenge"
  }
}

resource "aws_default_subnet" "subnetrenegociacao-dividas" {
  availability_zone = "ca-central-1a"

  tags = {
    Name = "Default subnet for ca-central-1a to Tech Challenge",
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/renegociacao-dividas" = "owned"
  }
}

resource "aws_default_subnet" "subnetrenegociacao-dividas2" {
  availability_zone = "ca-central-1b"

  tags = {
    Name = "Default subnet for ca-central-1b to Tech Challenge",
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/renegociacao-dividas" = "owned"
  }
}