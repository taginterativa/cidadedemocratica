function openMenu(linkId, menuId) {
  if ($(menuId).visible()) {
    $(menuId).hide();
  }
  else {
    $(menuId).show();
    $(linkId).addClassName('selected');
    
    Event.observe(document.body, 'click', function (e) {
      closeMenu(linkId, menuId, e);
    });
    Event.observe($(linkId), 'click', function (e) {
      closeMenu(linkId, menuId, e);
    });
  }
}

function closeMenu(linkId, menuId, event) {
  element = Event.element(event);
  if (element.id != linkId) {
    $(menuId).hide();
    $(linkId).removeClassName('selected');
    Event.stopObserving(document.body, 'click', function (e) {
      closeMenu(linkId, menuId, e);
    });
  }
}