// Mensajes (WOW)
var Messages = {};

// Mantiene el estado de la aplicación
var State = {
  // Contador para generar un ID único
  newIdCounter: 0,
  // Indicador de que alguna llamada por AJAX está en progreso
  ajaxInProgress: false
};

// Funciones de autocompletado
var AutoComplete = {
  observeAll: function() {
    $('input.autocomplete_field:not([data-observed])').each(function(){
      var input = $(this);
      
      input.autocomplete({
        source: function(request, response) {
          return jQuery.ajax({
            url: input.data('autocompleteUrl'),
            dataType: 'json',
            data: { q: request.term },
            success: function(data) {
              response(jQuery.map(data, function(item) {
                  var content = $('<div></div>');
                  
                  content.append(
                    $('<span class="label"></span>').text(item.label)
                  );
          
                  if(item.informal) {
                    content.append(
                      $('<span class="informal"></span>').text(item.informal)
                    );
                  }

                  return {label: content.html(), value: item.label, item: item};
                })
              );
            }
          });
        },
        type: 'get',
        select: function(event, ui) {
          var selected = ui.item;
          
          input.val(selected.value);
          input.data('item', selected.item);
          input.next('input.autocomplete_id').val(selected.item.id);
          
          input.trigger('autocomplete:update', input);
          
          return false;
        },
        open: function() {$('.ui-menu').css('width', input.width());}
      });
      
      input.data('autocomplete')._renderItem = function(ul, item) {
        return $('<li></li>').data('item.autocomplete', item).append(
          $('<a></a>').html(item.label)
        ).appendTo(ul);
      }
    }).data('observed', true);
  }
};

// Manejadores de eventos
var EventHandler = {
  /**
     * Agrega un ítem anidado
     */
  addNestedItem: function(e) {
    var template = eval(e.data('template'));

    $(e.data('container')).append(Util.replaceIds(template, /NEW_RECORD/g));

    e.trigger('item:added', e);
  },

  /**
     * Oculta un elemento (agregado con alguna de las funciones para agregado
     * dinámico)
     */
  hideItem: function(e) {
    Helper.hide($(e).parents($(e).data('target')));

    $(e).prev('input[type=hidden].destroy').val('1');

    $(e).trigger('item:hidden', $(e));
  },

  removeItem: function(e) {
    var target = e.parents(e.data('target'));

    Helper.remove(target, function() {
      target.trigger('item:removed', target);
    });
  },
  
  toggleMenu: function(e) {
    var target = $(e.data('target'));
    
    if(target.is(':visible:not(:animated)')) {
      target.stop().fadeOut(300, function() {
        $('span.arrow_up', e).removeClass('arrow_up').addClass('arrow_down');
      });
      
      target.removeClass('hide_when_show_menu');
    } else if (target.is(':not(:animated)')) {
      $('.hide_when_show_menu').stop().hide();
      $('span.arrow_up', $('#menu_links')).removeClass('arrow_up').
        addClass('arrow_down');
      
      target.stop().fadeIn(300, function() {
        $('span.arrow_down', e).removeClass('arrow_down').addClass('arrow_up');
      });
      
      target.addClass('hide_when_show_menu');
    }
  }
}

// Utilidades varias para asistir con efectos sobre los elementos
var Helper = {
  /**
     * Oculta el elemento indicado
     */
  hide: function(element, callback) {
    $(element).stop().slideUp(500, callback);
  },

  /**
     * Elimina el elemento indicado
     */
  remove: function(element, callback) {
    $(element).stop().slideUp(500, function() {
      $(this).remove();
      
      if(jQuery.isFunction(callback)) {callback();}
    });
  },

  /**
     * Muestra el ítem indicado (puede ser un string con el ID o el elemento mismo)
     */
  show: function(element, callback) {
    var e = $(element);

    if(e.is(':visible').length != 0) {
      e.stop().slideDown(500, callback);
    }
  }
}

// Utilidades varias
var Util = {
  /**
     * Combina dos hash javascript nativos
     */
  merge: function(hashOne, hashTwo) {
    return jQuery.extend({}, hashOne, hashTwo);
  },

  /**
     * Reemplaza todas las ocurrencias de la expresión regular 'regex' con un ID
     * único generado con la fecha y un número incremental
     */
  replaceIds: function(s, regex){
    return s.replace(regex, new Date().getTime() + State.newIdCounter++);
  }
}

jQuery(function($) {
  var eventList = $.map(EventHandler, function(v, k ) {return k;});
  
  // Para que los navegadores que no soportan HTML5 funcionen con autofocus
  $('*[autofocus]:not([readonly]):not([disabled]):visible:first').focus();
  
  $('a[data-event]').live('click', function(event) {
    if (event.stopped) return;
    var element = $(this);
    var eventName = element.data('event');

    if($.inArray(eventName, eventList) != -1) {
      EventHandler[eventName](element);
      
      event.preventDefault();
      event.stopPropagation();
    }
  });

  $('input.autocomplete_field').live('change', function() {
    var element = $(this);
    
    if(/^\s*$/.test(element.val())) {
      element.next('input.autocomplete_id:first').val('');
    }
  });
  
  $('#loading_caption').bind({
    ajaxStart: function() { $(this).stop(true, true).slideDown(100); },
    ajaxStop: function() { $(this).stop(true, true).slideUp(100); }
  });
  
  $(document).bind({
    ajaxStart: function() { State.ajaxInProgress = true; },
    ajaxStop: function() { State.ajaxInProgress = false; }
  });
  
  $('input.calendar:not(.hasDatepicker)').live('focus', function() {
    if($(this).data('time')) {
      $(this).datetimepicker({
        showOn: 'both',
        stepHour: 1,
        stepMinute: 5
      }).focus();
    } else {
      $(this).datepicker({
        showOn: 'both',
        onSelect: function() { $(this).datepicker('hide'); }
      }).focus();
    }
  });
  
  $('input.file').live('click', function() {
    $(this).parents('div.field:first').find('input[type="file"]').click();
  });
  
  $('a.fancybox').fancybox({type: 'image'});
  
  $('a.show').live('click', function(event) {
    $($(this).data('target')).stop(true, true).slideDown(300, function() {
      $(this).find('*[autofocus]:not([readonly]):not([disabled]):visible:first').focus()
    });
    
    event.preventDefault();
    event.stopPropagation();
  });
  
  $('input[type="file"]').filestyle({ 
    image: '/assets/choose-file.png',
    imageheight : 16,
    imagewidth : 16,
    width : 360
  });
  
  $('form').submit(function() {
    $(this).find('input[type="submit"], input[name="utf8"]').attr(
      'disabled', true
    );
  });
  
  // Verifica el estado de las llamadas AJAX antes de cerrar la ventana o
  // cambiar de página
  $(window).bind('beforeunload', function() {
    if (State.ajaxInProgress) {
      return Messages.ajaxInProgressWarning;
    } else {
      return undefined;
    }
  });

  AutoComplete.observeAll();
});

// Lograr que la función click() se comporte de la misma manera que un click
if (!HTMLAnchorElement.prototype.click) {
  HTMLAnchorElement.prototype.click = function() {
    var ev = document.createEvent('MouseEvents');
    ev.initEvent('click',true,true);
    if (this.dispatchEvent(ev) !== false) {
      //safari will have already done this, but I'm not sniffing safari
      //just in case they might in the future fix it; I figure it's better
      //to trigger the action twice than risk not triggering it at all
      document.location.href = this.href;
    }
  }
}