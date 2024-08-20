resource "null_resource" "deploy" {  
  provisioner "local-exec" {  
    command = "bash deploy-hello-world.sh"    
  }
}