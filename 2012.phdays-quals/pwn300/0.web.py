from twisted.web import server, resource
from twisted.internet import reactor



class Simple(resource.Resource):

	header = """<html>
<head>
<center><h1>SOUTH PARK GOVERMENT ADMIN PAGE</h1></center>
<!-- Something interesting: http://10.0.172.30/web.tar.gz -->
<!-- FLAG in /WEBFLAG -->
</head>
<hr>
<script>

function send() {
  var http = new XMLHttpRequest();
  var choice = 0;
  var actions = new Array();
  
  for (var i=0; i< document.getElementsByName("action").length; i++)
  {
	actions.push(document.getElementsByName("action")[i].value);
	if (document.getElementsByName("action")[i].checked == true)
		choice = i;
  }	
  
  
  params = "";
  for (var a=0; a<actions.length; a++) 
  {
    params += "&actions="+actions[a];
  }
  params += "&human="+document.getElementById("humans").value;
  params += "&choice="+encodeURIComponent(String.fromCharCode(choice));
  var url = "/";
  http.open("POST", url, true);

  http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");

  http.onreadystatechange = function() {//Call a function when the state changes.
  if(http.readyState == 4 && http.status == 200) {
 	document.getElementById("resp").innerHTML = http.responseText;
	}
  
  
	}
  http.send(params);
}
</script>"""
        body = """<body>
<form name="MainForm" d="MainForm" method="post" action=javascript:send()> 
	<select name="human" id="humans">
		<option value="Kenny">Kenny</option>
		<option value="Stan">Stan</option>
		<option value="Kyle">Kyle</option>
		<option value="Eric">Eric</option>
		<option value="Butters">Butters</option>
		<option value="Token">Token</option>
	</select>
	<br>
	<input type="radio" name="action" value="kill" checked=true>Kill<br>
	<input type="radio" name="action" value="arrest">Arrest<br>
	<input type="radio" name="action" value="bankrupt">Bankrupt<br>
	<input type="submit" value="Submit">
</form>
<div id='resp'>
</div>
"""
	footer = """</body>
</html>"""
	isLeaf = True        
	def render_GET(self, request):
	        response = self.header+self.body+self.footer
        	return response
	def render_POST(self, request):
		import process 
		addition = "<br>"
		addition += process.process(request.args)
		response = addition
		return response
site = server.Site(Simple())
reactor.listenTCP(2137, site)
reactor.run()

