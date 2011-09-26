<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
	<head>
		<meta http-equiv="content-type" content="text/html; charset=utf-8" />
		<script src=jquery.js></script>
		
		<script>
			$(function(){$('#body_board tr').each(function(index){if(index>0){$(this).click(function(){window.location='?no='+$(this).find('td').html();});$(this).hover(function(){$(this).css("background-color","green");$(this).css("color","white");$(this).css("cursor","pointer");},function(){$(this).css("background-color","white");$(this).css("color","black");});}else{$(this).click(function(){window.location='?sort=asc';});}});});
		</script>
		<style>
		body {
			padding: 0 auto;
			margin: 0 auto;
			font-family: Arial,Helvetica,sans-serif;
			font-size: 12px;
			line-height: 1.3em;
		}
		#main{
			padding: 0 auto;
			margin: 0 auto;
			width: 1000px;
			padding: 5px 10px 10px 10px;
			background: #ffffff; 
		}
		#board{
			margin: 0 auto;
			margin-top: 100px;
			width: 600px;
			height:600px;
			padding: 5px 10px 10px 10px;
			background: #ffffff; 
		
		}
		#head_board{
			padding-top:5px;
			padding-bottom:5px;
			color: green;
		}
		#body_board{
			margin:0px;
			padding:10px;
			margin-left:14px;
			width:550px;
			height:auto;
		}
		#body_foot_board{
			text-align:center;
			padding-top:6px;
		}
		#foot_board{
			text-align:center;
		}
		</style>
		<title>Challenge</title>
	</head>
	<body>
		<div id="container">	
			<div id="header"></div>
			<div id="main" style=''>
				<div id=board>
									<div id=head_board style='text-align:center'>Sboard</div>
					<div id=body_board style=''>
						<table bgcolor=white border=2 cellspacing=0 bordercolor=#4F9D24 frame=box rules=none width=100%>
							<tr><td width=30>No</td><td width=380>Subject</td><td width=40>Name</td><td width=70>Date</td></tr>
							<tr><td>6</td><td>Wowhacker ! </td><td>Wow</td><td>2011-08-27</td></tr><tr><td>5</td><td>Binary Guard</td><td>zzz</td><td>2011-08-22</td></tr><tr><td>4</td><td>Vguard for PC</td><td>Vman</td><td>2011-08-22</td></tr><tr><td>3</td><td>Vguard for smartphone</td><td>Vman</td><td>2011-08-22</td></tr><tr><td>2</td><td>Welcome !</td><td>Guest</td><td>2011-08-21</td></tr><tr><td>1</td><td><font color=red>Read me If you can</font></td><td>Admin</td><td>2011-08-20</td></tr>							
						</table>
					<div style='clear:both;'></div>
					<div id=body_foot_board>
						[<b>1</b>]
					</div>
					</div>
					<div id=foot_board>
						<form method=get>	
							<select name=type>
								<option  value=1>Subject</option>
								<option  value=2>Content</option>
								<option  value=3>Name</option>
							</select>
							<input type=text name="search" value="">
							<input type=submit value="Search">
						</form>
					</div>
								</div>
			</div>
			<div id="footer"></div>
		</div>

	</body>
</html>