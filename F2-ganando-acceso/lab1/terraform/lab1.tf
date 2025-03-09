# lab1-account-id-discovery/main.tf

provider "aws" {
  region = "us-east-1" # Asegúrate de que esta región tenga disponibles todos los servicios.
}

resource "aws_s3_bucket" "public_bucket" {
  bucket = "pentest-lab1-bucket-gosecurity-${random_id.hex}"
  force_destroy = true

  # Intentionally vulnerable configuration
  versioning {
    enabled = false
  }
}

resource "aws_s3_bucket_public_access_block" "public_bucket" {
  bucket = aws_s3_bucket.public_bucket.id
  
  # Intentionally permissive settings
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "public_bucket" {
  bucket = aws_s3_bucket.public_bucket.id
  acl    = "public-read-write"  # Intentionally vulnerable - allows anyone to read and write
  depends_on = [aws_s3_bucket_public_access_block.public_bucket]
}

# Intentionally overly permissive bucket policy
resource "aws_s3_bucket_policy" "public_bucket" {
  bucket = aws_s3_bucket.public_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadWriteAccess"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:*"]  # Allows all S3 actions
        Resource  = [
          "${aws_s3_bucket.public_bucket.arn}",
          "${aws_s3_bucket.public_bucket.arn}/*"
        ]
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.public_bucket]
}

resource "aws_s3_bucket_website_configuration" "public_bucket" {
  bucket = aws_s3_bucket.public_bucket.id
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_object" "pem_file" {
  bucket = aws_s3_bucket.public_bucket.id
  key    = "dummy.pem"
  content = "-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----\n" # Contenido ficticio.
  acl    = "public-read"
}

resource "aws_s3_bucket_object" "index_html" {
  bucket = aws_s3_bucket.public_bucket.id
  key    = "index.html"
  content = <<EOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hispanibank - Inicio</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f4f4f4;
            color: #333;
        }

        .banner {
            background-color: #0056b3;
            color: white;
            text-align: center;
            padding: 2rem 0;
        }

        .banner h1 {
            font-size: 2.5rem;
            margin-bottom: 0.5rem;
        }

        .banner p {
            font-size: 1.2rem;
        }

        .content {
            width: 80%;
            margin: 2rem auto;
            padding: 2rem;
            background-color: white;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            border-radius: 8px;
        }

        .content h2 {
            color: #0056b3;
        }
    </style>
</head>
<body>
    <header class="banner">
        <h1>Hispanibank</h1>
        <p>Tu banco de confianza</p>
    </header>

    <main class="content">
        <h2>Bienvenido al sitio web de pruebas de Hispanibank</h2>
        <p>Este es un sitio web ficticio creado para demostraciones de seguridad.</p>
        <p>Aquí encontrarías información confidencial si este fuera un banco real.</p>
    </main>
</body>
</html>
  EOF
  content_type = "text/html"
}

resource "random_id" "hex" {
  byte_length = 8
}

output "website_endpoint" {
  value = aws_s3_bucket.public_bucket.website_endpoint
}