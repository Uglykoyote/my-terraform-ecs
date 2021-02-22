resource "aws_key_pair" "key_pair" {
  key_name = "${lower(var.name)}-key_pair-${lower(var.environment)}"
  public_key = "${file("${var.key_path}")}"

  provisioner "local-exec" {
    command = "echo ${aws_key_pair.key_pair.public_key} | tee -a /root/.ssh/ec2_key.pem"
  }
}

resource "aws_instance" "instance" {
    count                       = "${var.number_of_instances}"

    ami                         = "${lookup(var.ami, var.region)}"
    instance_type               = "${var.ec2_instance_type}"
    key_name                    = "${aws_key_pair.key_pair.id}"
    subnet_id                   = "${var.subnet_id}"
	vpc_security_group_ids		= "${var.vpc_security_group_ids}"
    monitoring                  = "${var.monitoring}"
    #iam_instance_profile        = "${var.iam_instance_profile}"

    # Note: network_interface can't be specified together with associate_public_ip_address
    #network_interface           = "${var.network_interface}"
    associate_public_ip_address = "${var.enable_associate_public_ip_address}"
    private_ip                  = "${var.private_ip}"
    #ipv6_address_count          = "${var.ipv6_address_count}"
    #ipv6_addresses              = "${var.ipv6_addresses}"

    source_dest_check                    = "${var.source_dest_check}"
    disable_api_termination              = "${var.disable_api_termination}"
    instance_initiated_shutdown_behavior = "${var.instance_initiated_shutdown_behavior}"
    placement_group                      = "${var.placement_group}"
    tenancy                              = "${var.tenancy}"

    ebs_optimized          = "${var.ebs_optimized}"
    volume_tags            = "${var.volume_tags}"
    root_block_device {
        volume_size = "${var.disk_size}"
    #    volume_type = "gp2"
    }
    #ebs_block_device       = "${var.ebs_block_device}"
    #ephemeral_block_device = "${var.ephemeral_block_device}"

    lifecycle {
        create_before_destroy = true
        # Due to several known issues in Terraform AWS provider related to arguments of aws_instance:
        # (eg, https://github.com/terraform-providers/terraform-provider-aws/issues/2036)
        # we have to ignore changes in the following arguments
    }
	user_data = "${file("modules/ec2/script/user-data.sh")}"

    tags = {
        Name            = "${lower(var.name)}-ec2-${lower(var.environment)}-${count.index+1}"
        Environment     = "${var.environment}"
        Orchestration   = "${var.orchestration}"
        Createdby       = "${var.createdby}"
    }

    depends_on = ["aws_key_pair.key_pair"]
}
