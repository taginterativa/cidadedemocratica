
// Interface de montagem do Relatorio //
/**************************************/

// Marca (ou desmarca) todos os OPTIONS de um dado SELECT
function selectAll(selectBox, selectAll) {
  // have we been passed an ID
  if (typeof selectBox == "string") {
    selectBox = document.getElementById(selectBox);
  }
  // is the select box a multiple select box?
  if (selectBox.type == "select-multiple") {
    for (var i = 0; i < selectBox.options.length; i++) {
      selectBox.options[i].selected = selectAll;
    }
    document.getElementById('temas_selecionados').innerHTML = selectBox.options.length +" selecionados";
  }
}

// Habilita um dado SELECT
function habilitar(selectBox) {
  // have we been passed an ID
  if (typeof selectBox == "string") {
    selectBox = document.getElementById(selectBox);
  }
  // is the element disabled?
  if (selectBox.disabled) {
    selectBox.disabled = false;
  }
}

// Habilita um dado SELECT
function desabilitar(selectBox) {
  // have we been passed an ID
  if (typeof selectBox == "string") {
    selectBox = document.getElementById(selectBox);
  }
  if (selectBox) {
    selectBox.disabled = true;
    selectBox.writeAttribute('disabled', 'disabled');
  }
}

// Mostra/Esconde um DIV de acordo com o select escolhido
function trocarTipoAviso() {
  $('aviso_texto_simples').hide();
  $('aviso_arquivo_personalizado').hide();
  //alert($('settings_aviso_geral_tipo').value);
  if($('settings_aviso_geral_tipo').value=="texto") {
    $('aviso_texto_simples').show();
  }
  if($('settings_aviso_geral_tipo').value=="arquivo") {
    $('aviso_arquivo_personalizado').show();
  }
}
