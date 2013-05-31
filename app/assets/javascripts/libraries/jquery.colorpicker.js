/*
 * jQuery miniColors: A small color selector
 *
 * Copyright 2011 Cory LaViska for A Beautiful Site, LLC. (http://abeautifulsite.net/)
 *
 * Dual licensed under the MIT or GPL Version 2 licenses
 *
 */
if (jQuery)(function($) {

  $.extend($.fn, {

    colorpicker: function(o, data) {

      var create = function(input, o, data) {
          //
          // Creates a new instance of the miniColors selector
          //

          // Determine initial color (defaults to white)
          //				var color = expandHex(input.val());
          //				if( !color ) color = 'ffffff';
          var color = expandHexFromCss(input.val());
          var hsb = hex2hsb(color);
          //ALPHA START
          var colorInput = input.val();
          var alpha = getAlpha(input.val());
          //ALPHA END

          // Create trigger
          var trigger = $('<a class="miniColors-trigger" style="background-color: ' + colorInput + '" href="#"></a>');
          //				trigger.insertAfter(input);
          //ALPHA START
          var triggerHolder = $('<div class="miniColors-triggerHolder"></div>');
          triggerHolder.append(trigger);
          triggerHolder.insertAfter(input);
          //ALPHA END

          // Set input data and update attributes
          input.addClass('miniColors').data('original-maxlength', input.attr('maxlength') || null).data('original-autocomplete', input.attr('autocomplete') || null).data('letterCase', 'uppercase').data('trigger', trigger).data('hsb', hsb).data('alpha', alpha).data('change', o.change ? o.change : null).attr('maxlength', 22).attr('autocomplete', 'off')
          //ALPHA START
          .val(colorInput);
          //ALPHA END
          //					.val('#' + convertCase(color, o.letterCase));

          // Handle options
          if (o.readonly) input.prop('readonly', true);
          if (o.disabled) disable(input);

          // Show selector when trigger is clicked
          trigger.bind('click.miniColors', function(event) {
            event.preventDefault();
            if (input.val() === '') input.val('#');
            show(input);

          });

          // Show selector when input receives focus
          input.bind('focus.miniColors', function(event) {
            if (input.val() === '') input.val('#');
            show(input);
          });

          // Hide on blur
          input.bind('blur.miniColors', function(event) {
            //ALPHA START
            if (!isValidCssColor(input.val())) input.val('');
            //ALPHA END
            /*
					var hex = expandHex(input.val());
					input.val( hex ? '#' + convertCase(hex, input.data('letterCase')) : '' );
					*/
          });

          // Hide when tabbing out of the input
          input.bind('keydown.miniColors', function(event) {
            if (event.keyCode === 9) hide(input);
          });

          // Update when color is typed in
          input.bind('keyup.miniColors', function(event) {
            setColorFromInput(input);
          });

          // Handle pasting
          input.bind('paste.miniColors', function(event) {
            // Short pause to wait for paste to complete
            setTimeout(function() {
              setColorFromInput(input);
            }, 5);
          });

        };

      var destroy = function(input) {
          //
          // Destroys an active instance of the miniColors selector
          //
          hide();
          input = $(input);

          // Restore to original state
          input.data('trigger').remove();
          input.attr('autocomplete', input.data('original-autocomplete')).attr('maxlength', input.data('original-maxlength')).removeData().removeClass('miniColors').unbind('.miniColors');
          $(document).unbind('.miniColors');
        };

      var enable = function(input) {
          //
          // Enables the input control and the selector
          //
          input.prop('disabled', false).data('trigger').css('opacity', 1);
        };

      var disable = function(input) {
          //
          // Disables the input control and the selector
          //
          hide(input);
          input.prop('disabled', true).data('trigger').css('opacity', 0.5);
        };

      var show = function(input) {
          //
          // Shows the miniColors selector
          //
          if (input.prop('disabled')) return false;

          // Hide all other instances
          hide();

          // Generate the selector
          var selector = $('<div class="miniColors-selector"></div>');
          selector.append('<div class="miniColors-colors" style="background-color: #FFF;"><div class="miniColors-colorPicker"></div></div>').append('<div class="miniColors-hues"><div class="miniColors-huePicker"></div></div>')
          //ALPHA START
          .append('<div class="miniColors-alpha"><div class="miniColors-alphaPicker"></div></div>')
          //ALPHA END
          .css({
            top: input.is(':visible') ? input.offset().top + input.outerHeight() : input.data('trigger').offset().top + input.data('trigger').outerHeight(),
            left: input.is(':visible') ? input.offset().left : input.data('trigger').offset().left,
            display: 'none'
          }).addClass(input.attr('class'));

          // Set background for colors
          var hsb = input.data('hsb');
          selector.find('.miniColors-colors').css('backgroundColor', '#' + hsb2hex({
            h: hsb.h,
            s: 100,
            b: 100
          }));
          //ALPHA START
          selector.find('.miniColors-alpha').css('backgroundColor', '#' + hsb2hex(hsb));
          //ALPHA END

          // Set colorPicker position
          var colorPosition = input.data('colorPosition');
          if (!colorPosition) colorPosition = getColorPositionFromHSB(hsb);
          selector.find('.miniColors-colorPicker').css('top', colorPosition.y + 'px').css('left', colorPosition.x + 'px');

          // Set huePicker position
          var huePosition = input.data('huePosition');
          if (!huePosition) huePosition = getHuePositionFromHSB(hsb);
          selector.find('.miniColors-huePicker').css('top', huePosition.y + 'px');

          //ALPHA START
          // Set alphaPicker position
          var alpha = input.data('alpha');
          var alphaPosition = input.data('alphaPosition');
          if (!alphaPosition) alphaPosition = getAlphaPositionFromAlpha(alpha);
          selector.find('.miniColors-alphaPicker').css('top', alphaPosition.y + 'px');
          //ALPHA END

          // Set input data
          input.data('selector', selector)
          //ALPHA START
          .data('alphaPicker', selector.find('.miniColors-alphaPicker'))
          //ALPHA END
          .data('huePicker', selector.find('.miniColors-huePicker')).data('colorPicker', selector.find('.miniColors-colorPicker')).data('mousebutton', 0);

          $('BODY').append(selector);
          selector.fadeIn(100);

          // Prevent text selection in IE
          selector.bind('selectstart', function() {
            return false;
          });

          $(document).bind('mousedown.miniColors touchstart.miniColors', function(event) {

            input.data('mousebutton', 1);

            if ($(event.target).parents().andSelf().hasClass('miniColors-colors')) {
              event.preventDefault();
              input.data('moving', 'colors');
              moveColor(input, event);
            }

            if ($(event.target).parents().andSelf().hasClass('miniColors-hues')) {
              event.preventDefault();
              input.data('moving', 'hues');
              moveHue(input, event);
            }
            //ALPHA START
            if ($(event.target).parents().andSelf().hasClass('miniColors-alpha')) {
              event.preventDefault();
              input.data('moving', 'alpha');
              moveAlpha(input, event);
            }
            //ALPHA END
            if ($(event.target).parents().andSelf().hasClass('miniColors-selector')) {
              event.preventDefault();
              return;
            }

            if ($(event.target).parents().andSelf().hasClass('miniColors')) return;

            hide(input);
          });

          $(document).bind('mouseup.miniColors touchend.miniColors', function(event) {
            event.preventDefault();
            input.data('mousebutton', 0).removeData('moving');
          }).bind('mousemove.miniColors touchmove.miniColors', function(event) {
            event.preventDefault();
            if (input.data('mousebutton') === 1) {
              if (input.data('moving') === 'colors') moveColor(input, event);
              if (input.data('moving') === 'hues') moveHue(input, event);
              //ALPHA START
              if (input.data('moving') === 'alpha') moveAlpha(input, event);
              //ALPHA END
            }
          });

        };

      var hide = function(input) {

          //
          // Hides one or more miniColors selectors
          //

          // Hide all other instances if input isn't specified
          if (!input) input = '.miniColors';

          $(input).each(function() {
            var selector = $(this).data('selector');
            $(this).removeData('selector');
            $(selector).fadeOut(100, function() {
              $(this).remove();
            });
          });

          $(document).unbind('.miniColors');

        };

      var moveColor = function(input, event) {

          var colorPicker = input.data('colorPicker');

          colorPicker.hide();

          var position = {
            x: event.pageX,
            y: event.pageY
          };

          // Touch support
          if (event.originalEvent.changedTouches) {
            position.x = event.originalEvent.changedTouches[0].pageX;
            position.y = event.originalEvent.changedTouches[0].pageY;
          }
          position.x = position.x - input.data('selector').find('.miniColors-colors').offset().left - 5;
          position.y = position.y - input.data('selector').find('.miniColors-colors').offset().top - 5;
          if (position.x <= -5) position.x = -5;
          if (position.x >= 144) position.x = 144;
          if (position.y <= -5) position.y = -5;
          if (position.y >= 144) position.y = 144;

          input.data('colorPosition', position);
          colorPicker.css('left', position.x).css('top', position.y).show();

          // Calculate saturation
          var s = Math.round((position.x + 5) * 0.67);
          if (s < 0) s = 0;
          if (s > 100) s = 100;

          // Calculate brightness
          var b = 100 - Math.round((position.y + 5) * 0.67);
          if (b < 0) b = 0;
          if (b > 100) b = 100;

          // Update HSB values
          var hsb = input.data('hsb');
          hsb.s = s;
          hsb.b = b;

          // Set color
          setColor(input, hsb, null, true);
        };

      var moveHue = function(input, event) {

          var huePicker = input.data('huePicker');

          huePicker.hide();

          var position = {
            y: event.pageY
          };

          // Touch support
          if (event.originalEvent.changedTouches) {
            position.y = event.originalEvent.changedTouches[0].pageY;
          }

          position.y = position.y - input.data('selector').find('.miniColors-colors').offset().top - 1;
          if (position.y <= -1) position.y = -1;
          if (position.y >= 149) position.y = 149;
          input.data('huePosition', position);
          huePicker.css('top', position.y).show();

          // Calculate hue
          var h = Math.round((150 - position.y - 1) * 2.4);
          if (h < 0) h = 0;
          if (h > 360) h = 360;

          // Update HSB values
          var hsb = input.data('hsb');
          hsb.h = h;

          // Set color
          setColor(input, hsb, null, true);

        };

      //ALPHA START
      var moveAlpha = function(input, event) {

          var alphaPicker = input.data('alphaPicker');

          alphaPicker.hide();

          var position = {
            y: event.pageY
          };

          // Touch support
          if (event.originalEvent.changedTouches) {
            position.y = event.originalEvent.changedTouches[0].pageY;
          }

          position.y = position.y - input.data('selector').find('.miniColors-colors').offset().top - 1;
          if (position.y <= -1) position.y = -1;
          if (position.y >= 149) position.y = 149;
          input.data('alphaPosition', position);
          alphaPicker.css('top', position.y).show();

          // Calculate alpha
          var alpha_scale_100 = Math.round((150 - position.y - 1) * 2 / 3);
          //get alpha with 0.05 accuracy
          var alpha = parseFloat(Math.round(alpha_scale_100 / 5) * 5 / 100);
          if (alpha < 0.05) alpha = 0;
          if (alpha > 0.95) alpha = 1;

          // Set color
          setColor(input, null, alpha, true);
        };

      var getCssColor = function(input) {
          switch (input.data('alpha')) {
          case 1:
            //return ordinary #hex
            var hex = hsb2hex(input.data('hsb'));
            return '#' + convertCase(hex, input.data('letterCase'));
          case 0:
            //blank color
            return '';
          default:
            //return rgba()
            var rgb = hsb2rgb(input.data('hsb'));
            return 'rgba(' + rgb.r + ',' + rgb.g + ',' + rgb.b + ',' + input.data('alpha') + ')';
          }
        };
      //ALPHA END
      var setColor = function(input, hsb, alpha, updateInput) {
          if (hsb != null) input.data('hsb', hsb);
          //ALPHA START
          if (alpha != null) input.data('alpha', alpha);
          hsb = input.data('hsb');
          alpha = input.data('alpha');
          var cssColor = getCssColor(input);
          if (updateInput) input.val(cssColor);
          input.data('trigger').css('backgroundColor', cssColor);
          //ALPHA END
          /*
				var hex = hsb2hex(hsb);
				if( updateInput ) input.val( '#' + convertCase(hex, input.data('letterCase')) );
				input.data('trigger').css('backgroundColor', '#' + hex);
				*/
          //ALPHA START (extended if-statement)
          if (input.data('selector')) {
            //update color palette
            input.data('selector').find('.miniColors-colors').css('backgroundColor', '#' + hsb2hex({
              h: hsb.h,
              s: 100,
              b: 100
            }));
            //update alpha color
            input.data('selector').find('.miniColors-alpha').css('backgroundColor', '#' + hsb2hex(hsb));
          }
          //ALPHA END

          // Fire change callback
          if (input.data('change')) {
            //ALPHA START
            if (cssColor === input.data('lastChange')) return;
            input.data('change').call(input, cssColor, hsb2rgb(hsb));
            input.data('lastChange', cssColor);
            //ALPHA END
            /*
					if( hex === input.data('lastChange') ) return;
					input.data('change').call(input, '#' + hex, hsb2rgb(hsb));
					input.data('lastChange', hex);
					*/
          }

          //ALPHA
          /*
				var myRgb=hsb2rgb(hsb);
				var rgbCss='rgb('+myRgb.r+','+myRgb.g+','+myRgb.b+')';
				trace(rgbCss);
				*/
        };

      var setColorFromInput = function(input) {

          /*
				input.val('#' + cleanHex(input.val()));
				var hex = expandHex(input.val());
				if( !hex ) return false;
				*/
          //ALPHA START
          input.val(cleanCssColor(input.val()));
          if (!isValidCssColor(input.val())) return false;

          var hex = expandHexFromCss(input.val());
          //ALPHA END


          // Get HSB equivalent
          var hsb = hex2hsb(hex);
          //ALPHA START
          var alpha = getAlpha(input.val());
          //ALPHA END

          // If color is the same, no change required
          var currentHSB = input.data('hsb');
          //ALPHA START
          var currentAlpha = input.data('alpha');
          //ALPHA END
          if (hsb.h === currentHSB.h && hsb.s === currentHSB.s && hsb.b === currentHSB.b && currentAlpha === alpha) return true;

          // Set colorPicker position
          var colorPosition = getColorPositionFromHSB(hsb);
          var colorPicker = $(input.data('colorPicker'));
          colorPicker.css('top', colorPosition.y + 'px').css('left', colorPosition.x + 'px');
          input.data('colorPosition', colorPosition);

          // Set huePosition position
          var huePosition = getHuePositionFromHSB(hsb);
          var huePicker = $(input.data('huePicker'));
          huePicker.css('top', huePosition.y + 'px');
          input.data('huePosition', huePosition);

          //ALPHA START
          // Set alphaPosition position
          var alphaPosition = getAlphaPositionFromAlpha(alpha);
          var alphaPicker = $(input.data('alphaPicker'));
          alphaPicker.css('top', alphaPosition.y + 'px');
          input.data('alphaPosition', alphaPosition);
          //ALPHA END
          setColor(input, hsb, alpha);

          return true;

        };

      var convertCase = function(string, letterCase) {
          if (letterCase === 'lowercase') return string.toLowerCase();
          if (letterCase === 'uppercase' ) return string.toUpperCase();
          return string;
        };

      var getColorPositionFromHSB = function(hsb) {
          var x = Math.ceil(hsb.s / 0.67);
          if (x < 0) x = 0;
          if (x > 150) x = 150;
          var y = 150 - Math.ceil(hsb.b / 0.67);
          if (y < 0) y = 0;
          if (y > 150) y = 150;
          return {
            x: x - 5,
            y: y - 5
          };
        };

      var getHuePositionFromHSB = function(hsb) {
          var y = 150 - (hsb.h / 2.4);
          if (y < 0) y = 0;
          if (y > 150) y = 150;
          return {
            y: y - 1
          };
        };

      //ALPHA START
      var getAlphaPositionFromAlpha = function(alpha) {
          var y = 150 - (alpha / 2 * 3 * 100);
          if (y < 0) y = 0;
          if (y > 150) y = 150;
          return {
            y: y - 1
          };
        };

      var isValidCssColor = function(value) {
          return (isHex(value) || isRgba(value));
        }

      var expandHexFromCss = function(value) {
          value = cleanCssColor(value);
          if (!value) return '';
          if (isRgba(value)) {
            var rgba = convertCssRgba(value);
            if (rgba) return rgba2Hex(rgba);
          } else {
            var hex = expandHex(value);
            if (hex) return hex;
          }
          return '';
        };

      var convertCssRgba = function(value) {
          //convert css string "rgba(12,43,235,0.5)" to rgba object
          try {
            value = stripWhiteSpace(value);
            var rgba = value.split('(')[1].split(')')[0].split(',');
            return {
              r: parseInt(rgba[0]),
              g: parseInt(rgba[1]),
              b: parseInt(rgba[2]),
              a: parseFloat(rgba[3])
            };
          } catch (err) {
            return null;
          }
        }

      var cleanCssColor = function(value) {
          value = value.replace(/[^#A-F0-9rgba,\(\)\.]/ig, '');
          /*
				if ( isHex(value) )
					value = convertCase(value, input.data('letterCase'));
				*/
          return value;
        };

      var isHex = function(value) {
          return /(^#[0-9A-F]{6}$)|(^#[0-9A-F]{3}$)/i.test(value);
        }

      var isRgba = function(value) {
          value = stripWhiteSpace(value);
          return /(^rgba\([0-9]{1,3},[0-9]{1,3},[0-9]{1,3},[0-9\.]{1,4}\)$)/i.test(value);
        }

      var rgba2Hex = function(rgba) {
          return rgb2hex({
            r: rgba.r,
            g: rgba.g,
            b: rgba.b
          })
        }

      var stripWhiteSpace = function(value) {
          return value.replace(/\s/g, '');
        }

      var getAlpha = function(value) {
          if (isRgba(value)) {
            var rgba = convertCssRgba(value);
            if (rgba) return rgba.a;
          }
          return 1;
        }

      var css2hsb = function(value) {
          if (isHex(value)) {
            return hex2hsb(expandHex(value));
          } else if (isRgba(value)) {
            var rgba = convertCssRgba(value);
            if (rgba) return rgba2Hex(rgba);
            else return null;
          }
          return null;
        }

        //ALPHA END
      var cleanHex = function(hex) {
          return hex.replace(/[^A-F0-9]/ig, '');
        };

      var expandHex = function(hex) {
          hex = cleanHex(hex);
          if (!hex) return null;
          if (hex.length === 3) hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
          return hex.length === 6 ? hex : null;
        };

      var hsb2rgb = function(hsb) {
          var rgb = {};
          var h = Math.round(hsb.h);
          var s = Math.round(hsb.s * 255 / 100);
          var v = Math.round(hsb.b * 255 / 100);
          if (s === 0) {
            rgb.r = rgb.g = rgb.b = v;
          } else {
            var t1 = v;
            var t2 = (255 - s) * v / 255;
            var t3 = (t1 - t2) * (h % 60) / 60;
            if (h === 360) h = 0;
            if (h < 60) {
              rgb.r = t1;
              rgb.b = t2;
              rgb.g = t2 + t3;
            } else if (h < 120) {
              rgb.g = t1;
              rgb.b = t2;
              rgb.r = t1 - t3;
            } else if (h < 180) {
              rgb.g = t1;
              rgb.r = t2;
              rgb.b = t2 + t3;
            } else if (h < 240) {
              rgb.b = t1;
              rgb.r = t2;
              rgb.g = t1 - t3;
            } else if (h < 300) {
              rgb.b = t1;
              rgb.g = t2;
              rgb.r = t2 + t3;
            } else if (h < 360) {
              rgb.r = t1;
              rgb.g = t2;
              rgb.b = t1 - t3;
            } else {
              rgb.r = 0;
              rgb.g = 0;
              rgb.b = 0;
            }
          }
          return {
            r: Math.round(rgb.r),
            g: Math.round(rgb.g),
            b: Math.round(rgb.b)
          };
        };

      var rgb2hex = function(rgb) {
          var hex = [
          rgb.r.toString(16), rgb.g.toString(16), rgb.b.toString(16)];
          $.each(hex, function(nr, val) {
            if (val.length === 1) hex[nr] = '0' + val;
          });
          return hex.join('');
        };

      var hex2rgb = function(hex) {
          hex = parseInt(((hex.indexOf('#') > -1) ? hex.substring(1) : hex), 16);

          return {
            r: hex >> 16,
            g: (hex & 0x00FF00) >> 8,
            b: (hex & 0x0000FF)
          };
        };

      var rgb2hsb = function(rgb) {
          var hsb = {
            h: 0,
            s: 0,
            b: 0
          };
          var min = Math.min(rgb.r, rgb.g, rgb.b);
          var max = Math.max(rgb.r, rgb.g, rgb.b);
          var delta = max - min;
          hsb.b = max;
          hsb.s = max !== 0 ? 255 * delta / max : 0;
          if (hsb.s !== 0) {
            if (rgb.r === max) {
              hsb.h = (rgb.g - rgb.b) / delta;
            } else if (rgb.g === max) {
              hsb.h = 2 + (rgb.b - rgb.r) / delta;
            } else {
              hsb.h = 4 + (rgb.r - rgb.g) / delta;
            }
          } else {
            hsb.h = -1;
          }
          hsb.h *= 60;
          if (hsb.h < 0) {
            hsb.h += 360;
          }
          hsb.s *= 100 / 255;
          hsb.b *= 100 / 255;
          return hsb;
        };

      var hex2hsb = function(hex) {
          var hsb = rgb2hsb(hex2rgb(hex));
          // Zero out hue marker for black, white, and grays (saturation === 0)
          if (hsb.s === 0) hsb.h = 360;
          return hsb;
        };

      var hsb2hex = function(hsb) {
          return rgb2hex(hsb2rgb(hsb));
        };


      // Handle calls to $([selector]).miniColors()
      switch (o) {

      case 'readonly':

        $(this).each(function() {
          if (!$(this).hasClass('miniColors')) return;
          $(this).prop('readonly', data);
        });

        return $(this);

      case 'disabled':

        $(this).each(function() {
          if (!$(this).hasClass('miniColors')) return;
          if (data) {
            disable($(this));
          } else {
            enable($(this));
          }
        });

        return $(this);

      case 'value':

        // Getter
        if (data === undefined) {
          if (!$(this).hasClass('miniColors')) return;
          //ALPHA START
          var input = $(this),
            cssColor = expandHexFromCss(input.val());
          return cssColor ? '#' + cssColor : null;
          //ALPHA END
          /*
						var input = $(this),
							hex = expandHex(input.val());
						return hex ? '#' + convertCase(hex, input.data('letterCase')) : null;
						*/
        }

        // Setter
        $(this).each(function() {
          if (!$(this).hasClass('miniColors')) return;
          $(this).val(data);
          setColorFromInput($(this));
        });

        return $(this);

      case 'destroy':

        $(this).each(function() {
          if (!$(this).hasClass('miniColors')) return;
          destroy($(this));
        });

        return $(this);

      default:

        if (!o) o = {};

        $(this).each(function() {

          // Must be called on an input element
          if ($(this)[0].tagName.toLowerCase() !== 'input') return;

          // If a trigger is present, the control was already created
          if ($(this).data('trigger')) return;

          // Create the control
          create($(this), o, data);

        });

        return $(this);

      }

    }

  });

})(jQuery);