<?php
$e_type = $_POST['e_type'];
$text = $_POST['text'];

if(strcmp($e_type,'1337')==0){
	$exe="./" . $e_type
}

elseif(strcmp($e_type,'caesar')==0){
	$exe="python" . " " . $e_type . ".py"
}

elseif(strcmp($e_type,'Base64')==0){
	$exe="./Base64"
}

elseif(strcmp($e_type,'Salsa20')==0){
	$exe="swift" . " " . $e_type
}

elseif(strcmp($e_type,'sha1')==0){
	$exe="ruby" . " " . $e_type
}

else{
	$exe="none"
}

if(strcmp($e_type,'none')!=0){
	$command=$exe . " " . $text;
	$response = exec($command);
	echo $response;
}
?>
