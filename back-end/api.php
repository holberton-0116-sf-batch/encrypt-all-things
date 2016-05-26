<?php
$e_type = $_GET['e_type'];
$text = $_GET['text'];
//if statements
$command="./" . $e_type . " " . $text;
$response = exec($command);
echo $response;
?>
