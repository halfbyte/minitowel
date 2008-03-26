// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
Event.observe(window, 'dom:loaded', function(e) {
  if ($('cardList')) {
    Sortable.create('cardList', {constraint:false,  overlap:'horizontal', onUpdate: function(list) {
      new Ajax.Request(orderURL, {
        parameters: Sortable.serialize(list),
        
      })
    }})
    if ($('zoomer')) {
      $$('#zoomer li a').each(function(zoomerLink) {
        zoomerLink.observe('click', function(event) {
          zoomTo = zoomerLink.innerHTML
          $('cardList').removeClassName("size" + oldSize).addClassName("size" + zoomTo)
          oldSize = zoomTo
          new Ajax.Request(zoomURL, {
            parameters: { zl: zoomTo }
          })
        })
      })
      
    }
    if ($('zoomSlider')) {
      new Control.Slider('zoomSliderHandle', 'zoomSlider', {
        sliderValue: oldSize,
        range: $R(1,4),
        values: [1,2,3,4],
        onChange: function(value, slider) {
          $('cardList').removeClassName("size" + oldSize).addClassName("size" + value)
          oldSize = value
          new Ajax.Request(zoomURL, {
            parameters: { zl: value }
          })
        },
        onSlide: function(value, slider) {
          $('cardList').removeClassName("size" + oldSize).addClassName("size" + value)
          oldSize = value
        }
      });
    }
    $$('ul#cardList li.card').each(function(element) {
      element.observe('click', function() {
        var now = new Date().getTime();
        // TODO: Übliche Werte f. Doppelklick?
        if (element.lastClicked && (element.lastClicked + 500) > now) {
          // this is a double click!
          console.log(element.select('.editLink').first().href)
          window.location.href = element.select('.editLink').first().href
        } else {
          element.lastClicked = now
        }

      })
    })
    
    
  }
  Ajax.Responders.register({ 
    onCreate: function() { $('spinner').show(); }, 
    onComplete: function() { 
      if (0 == Ajax.activeRequestCount) 
        $('spinner').visualEffect('fade'); 
    } 
  });
})

