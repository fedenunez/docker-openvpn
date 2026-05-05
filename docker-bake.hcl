variable "IMAGE_NAME" {
  default = "fedenunez/openvpn"
}

variable "ALPINE_VERSION" {
  default = "3.23"
}

group "default" {
  targets = ["openvpn"]
}

target "openvpn" {
  context = "."
  dockerfile = "Dockerfile"
  platforms = ["linux/amd64", "linux/arm64"]
  tags = ["${IMAGE_NAME}:latest"]
  args = {
    ALPINE_VERSION = "${ALPINE_VERSION}"
  }
}
