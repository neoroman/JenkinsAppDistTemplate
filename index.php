<?php
require('src/config.php');
if (isset($_GET['url'])) {
    header('Location: src/'. $_GET['url']);  
}
?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD>
<TITLE><?php echo L::company_name; ?> Support</TITLE>
<META http-equiv='REFRESH' content='0;url=/<?php echo $topPath; ?>/dist_client.php'>
</HEAD>
<BODY>
    Redirection to APP Distribution Page for Client
</BODY>
</HTML>

