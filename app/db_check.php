<?php
$host = "terraform-20260208073718626400000004.c162o0mie7ts.us-east-1.rds.amazonaws.com";
$user = "admin";
$pass = "Keert17@";

$conn = mysqli_connect($host, $user, $pass);

if ($conn) {
    echo "Database Connected Successfully";
} else {
    echo "Database Connection Failed";
}
?>

