# Copyright (c) 2008 Thiago Arrais
#
# This file is part of rODF.
#
# rODF is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.

# rODF is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License
# along with rODF.  If not, see <http://www.gnu.org/licenses/>.

require 'rubygems'
require 'builder'

module ODF
  class Property
    PROPERTY_NAMES = {:cell => 'table-cell-properties',
                      :text => 'text-properties',
                      :column => 'table-column-properties',
                      :row => 'table-row-properties',
                      :conditional => 'map'}
    TRANSLATED_SPECS = [:border_color, :border_style, :border_width]

    STYLE_ATTRIBUTES =
      ['column-width', 'rotation-angle', 'text-underline-type', 'tab-stop-distance',
       'condition', 'apply-style-name', 'base-cell-address', 'row-height',
       'country-asian', 'country-complex', 'font-charset', 'font-charset-asian',
       'font-charset-complex', 'font-family-asian', 'font-family-complex', 'font-family-generic',
       'font-family-generic-asian', 'font-family-generic-complex', 'font-name', 'font-name-asian',
       'font-name-complex', 'font-pitch', 'font-pitch-asian', 'font-pitch-complex', 'font-relief',
       'font-size-asian', 'font-size-complex', 'font-size-rel', 'font-size-rel-asian',
       'font-size-rel-complex', 'font-style-asian', 'font-style-complex', 'font-style-name',
       'font-style-name-asian', 'font-style-name-complex', 'font-weight-asian', 'font-weight-complex',
       'language-asian', 'language-complex', 'letter-kerning', 'rfc-language-tag',
       'rfc-language-tag-asian', 'rfc-language-tag-complex', 'script-asian', 'script-complex',
       'script-type', 'text-blinking', 'text-combine', 'text-combine-end-char',
       'text-combine-start-char', 'text-emphasize', 'text-line-through-color',
       'text-line-through-mode', 'text-line-through-style', 'text-line-through-text',
       'text-line-through-text-style', 'text-line-through-type', 'text-line-through-width',
       'text-outline', 'text-overline-color', 'text-overline-mode', 'text-overline-style',
       'text-overline-type', 'text-overline-width', 'text-position', 'text-rotation-angle',
       'text-rotation-scale', 'text-scale', 'text-underline-color', 'text-underline-mode',
       'text-underline-style', 'text-underline-width', 'use-window-font-color',
       'border-line-width', 'border-line-width-bottom', 'border-line-width-left',
       'border-line-width-right', 'border-line-width-top', 'cell-protect', 'decimal-places',
       'diagonal-bl-tr', 'diagonal-bl-tr-widths', 'diagonal-tl-br', 'diagonal-tl-br-widths',
       'direction', 'glyph-orientation-vertical', 'print-content', 'repeat-content',
       'rotation-align', 'shadow', 'shrink-to-fit', 'text-align-source',
       'vertical-align', 'writing-mode', 'min-row-height', 'use-optimal-row-height',
       'rel-column-width', 'use-optimal-column-width', 'auto-text-indent', 'background-transparency',
       'font-independent-line-spacing', 'join-border', 'justify-single-word', 'line-break',
       'line-height-at-least', 'line-spacing', 'page-number', 'punctuation-wrap', 'register-true',
       'snap-to-layout-grid', 'text-autospace',
       'writing-mode-automatic']

    def initialize(type, specs={})
      @name = 'style:' + (PROPERTY_NAMES[type] || "#{type}-properties")
      @specs = translate(specs).map { |k, v| [k.to_s, v] }
    end

    def xml
      specs = @specs.inject({}) do |acc, kv|
        acc.merge Property.lookup_namespace_for(kv.first) + ':' + kv.first => kv.last
      end
      Builder::XmlMarkup.new.tag! @name, specs
    end

    class << self
      def lookup_namespace_for(property_name)
        STYLE_ATTRIBUTES.include?(property_name) ? 'style' : 'fo'
      end
    end
  private
    def translate(specs)
      result = specs.clone
      tspecs = specs.select {|k, v| TRANSLATED_SPECS.include? k}
      tspecs.map {|k, v| result.delete k}
      tspecs = tspecs.inject({}) {|acc, e| acc.merge e.first => e.last}
      if tspecs[:border_width] && tspecs[:border_style] && tspecs[:border_color] then
        width = tspecs[:border_width].split
        style = tspecs[:border_style].split
        color = tspecs[:border_color].split
        if width.length == 1 && style.length == 1 && color.length == 1 then
          result[:border] = [width[0], style[0], color[0]].join(' ')
        else
          result['border-top'] = cascading_join(width, style, color, 0)
          result['border-right'] = cascading_join(width, style, color, 1, 0)
          result['border-bottom'] = cascading_join(width, style, color, 2, 0)
          result['border-left'] = cascading_join(width, style, color, 3, 1, 0)
        end
      end
      result
    end

    def cascading_join(width_parts, style_parts, color_parts, *prefs)
      [ cascade(width_parts, prefs),
        cascade(style_parts, prefs),
        cascade(color_parts, prefs)].join(' ')
    end

    def cascade(list, prefs)
      prefs.inject(nil) {|acc, i| acc || list[i]}
    end
  end
end

