<?php
$e_type = $_POST['e_type'];
$text = $_POST['text'];
//if statements
$command="./" . $e_type . " " . $text;
$response = exec($command);
echo $response;
?>
