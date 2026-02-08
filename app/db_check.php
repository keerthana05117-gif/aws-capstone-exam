<?php
$host = "RDS_ENDPOINT_HERE";
$user = "admin";
$pass = "password123";

$conn = mysqli_connect($host, $user, $pass);

if ($conn) {
    echo "Database Connected Successfully";
} else {
    echo "Database Connection Failed";
}
?>

