<?php

require '../itmo-544-env/vendor/autoload.php';
#require 'vendor/autoload.php';

use Aws\Rds\RdsClient;
$client = RdsClient::factory(array(
'version'=>'latest',
'region'=> 'us-west-2'
));


#$rds = RdsClient::factory(array(
#'version'=>'latest',
#'region'  => 'us-west-2'
#));

#$result = $client->describeDBInstances(array(
#    'DBInstanceIdentifier' => 'jrx-db',
#));

$endpoint = ""; 

#foreach ($result->getPath('DBInstances/*/Endpoint/Address') as $ep) {
    // Do something with the message
#    echo "============". $ep . "================";
#    $endpoint = $ep;
#}

$result = $client->waitUntil('DBInstanceAvailable',['DBInstanceIdentifier' => 'jrx-db',
]);
print_r($result);
$endpoint = $result['DBInstances'][0]['Endpoint']['Address'];
    echo "============\n". $endpoint . "================";

print_r($endpoint);  
echo "begin database";
#$link = mysqli_connect($endpoint,"controller","ilovebunnies","itmo544db",3306) or die("Error " . mysqli_error($link));
#$link = mysqli_connect("jrx-db.cwom1zatgb1y.us-west-2.rds.amazonaws.com","rjing","mypoorphp","itmo544mp1") or die("Error " . mysqli_error($link));
$link = mysqli_connect($endpoint,"rjing","mypoorphp","itmo544mp1") or die("Error " . mysqli_error($link));
/* check connection */
if (mysqli_connect_errno()) {
    printf("Connect failed: %s\n", mysqli_connect_error());
    exit();
}
/*
$delete_table = 'DELETE TABLE student';
$del_tbl = $link->query($delete_table);
if ($delete_table) {
        echo "Table student has been deleted";
}
else {
        echo "error!!";

}
*/
$create_table = 'CREATE TABLE IF NOT EXISTS mp1tb  
(
    id INT NOT NULL AUTO_INCREMENT,
    email VARCHAR(200) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    filename VARCHAR(255) NOT NULL,
    s3rawurl VARCHAR(255) NOT NULL,
    s3finishedurl VARCHAR(255) NOT NULL,
    status INT NOT NULL,
    issubscribed INT NOT NULL,
    PRIMARY KEY(id)
)';
$create_tbl = $link->query($create_table);
if ($create_table) {
	echo "Table is created or No error returned.";
}
else {
        echo "error!!";  
}
$link->close();
?>
