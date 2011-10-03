/**
 * @author marcelo marqueti
 */
 var id_owner = "";
 var id_viewer = "";

function getData() {
	
	var req = opensocial.newDataRequest();
	// req.add(req.newFetchPersonRequest('VIEWER'), 'viewer');
	var viewer = opensocial.IdSpec.PersonId.VIEWER;
	req.add(req.newFetchPersonRequest(viewer), 'viewer');
	
	var owner = opensocial.IdSpec.PersonId.OWNER;
	req.add(req.newFetchPersonRequest(owner), 'owner');
	
	req.send(getDataRe);

};

function getDataRe(data) {
	var viewer = data.get("viewer").getData();
	var owner = data.get("owner").getData();
	var name = viewer.getDisplayName();
	//var thumb = viewer.getField(opensocial.Person.Field.THUMBNAIL_URL);

	id_owner = owner.getId();
	id_viewer = viewer.getId();
	
	document.getElementById('id_owner').value = id_owner;
	document.getElementById('id_viewer').value = id_viewer;
	
	var html = name;
	
	if(id_owner != id_viewer){
		html += ' : visitante';
	} else {
		html += ' : dono';
	}
	
	document.getElementById('menu').innerHTML = html;

	//recupera os dados sobre o aplicativo
	if (gadgets.util.hasFeature("ning")) {
		ning.app.getInfo(getAppsInfoRe);
	} else {
		alert("Está rodando fora do NING!");
	}
	
	//chama o que vai ver se já tem o app instalado
	verificaInstacao(id_owner);
	
};

function getAppsInfoRe(data) {
	if (data.hadError()) {
		alert("Ocorreu um erro ao acessar o aplicativo!");
	} else {
		alert("Campo " + ning.app.Field.ID + ": " + data.getField(ning.app.Field['ID']));
		id_apps = data.getField(ning.app.Field['ID']);
		document.getElementById('id_apps').value = id_apps;
		
	}
};

function verificaInstacao(id_owner){
	
	/*
		recuperar esse item -> t.integer  "user_id"
	    recuperar esse item -> t.integer  "source_id"
	    paramentros a serem enviados -> t.string   "owner_id"
	    paramentros a serem enviados -> t.string   "apps_id"
	*/ 

	
	
     var params = {};
     var postdata = {
     	id_owner : id_owner 
     };

	var params = {};
	params[gadgets.io.RequestParameters.CONTENT_TYPE] = gadgets.io.ContentType.HTML;
	//var url = "http://cidadedemocratica.org.br/bugigangas/verificaNingApps";
	var url = "http://cidadedemocratica.org.br/perfil_ning/869";
	gadgets.io.makeRequest(url, verificaInstacaoRe, params);
 }; 
function verificaInstacaoRe(obj) {

	var resposta = obj.data;
//	alert(resposta);
	
	document.getElementById('conteudo').innerHTML = resposta;

//	if(resposta == 'dono' || resposta == 'convidado'){
//		//postarUpdate('Adicionou o aplicativo do Casamento do Ponto Frio');
//		homeCadastradoShow();
//	} else {
//		homeShow();
//	}

};


function novoNingApps(id_owner){
	
     var params = {};
     var postdata = {
     	id_owner : id_owner 
     };

	var params = {};
	// Content types available at http://code.google.com/apis/opensocial/docs/0.7/reference/
	params[gadgets.io.RequestParameters.CONTENT_TYPE] = gadgets.io.ContentType.HTML;
	var url = "http://cidadedemocratica.org.br/bugigangas/novoNingApps";
	gadgets.io.makeRequest(url, novoNingAppsRe, params);

 }; 
function novoNingAppsRe(obj) {
	var resposta = obj.data;
	document.getElementById('conteudo').innerHTML = resposta;
};
