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

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'odf/property'

describe ODF::Property do
  it "should accept either strings or symbols as keys" do
    property = ODF::Property.new :text, :color=>'#4c4c4c', 'font-weight'=>'bold'
    elem = Hpricot(property.xml).at('style:text-properties')
    elem['fo:color'].should == '#4c4c4c'
    elem['fo:font-weight'].should == 'bold'
  end

  it "should prefix style properties with looked up namespace" do
    Hpricot(ODF::Property.new(:cell, 'rotation-angle' => '-90').xml).
      at('//style:table-cell-properties')['style:rotation-angle'].should == '-90'
    Hpricot(ODF::Property.new(:row, 'row-height' => '2cm').xml).
      at('//style:table-row-properties')['style:row-height'].should == '2cm'
    Hpricot(ODF::Property.new(:column, 'column-width' => '2cm').xml).
      at('//style:table-column-properties')['style:column-width'].should == '2cm'
    Hpricot(ODF::Property.new(:text, 'text-underline-type' => 'single').xml).
      at('style:text-properties')['style:text-underline-type'].should == 'single'
    Hpricot(ODF::Property.new(:paragraph, 'tab-stop-distance' => '0.4925in').xml).
      at('style:paragraph-properties')['style:tab-stop-distance'].should == '0.4925in'
  end

  it "should generate row properties tag" do
    property = ODF::Property.new :row, 'background-color' => '#f5f57a'

    property.xml.should have_tag('//style:table-row-properties')
  end

  it "should accept full perimeter border specs" do
    property = ODF::Property.new :cell, :border => "0.025in solid #000000"

    Hpricot(property.xml).at('//style:table-cell-properties')['fo:border'].
      should == "0.025in solid #000000"
  end

  it "should accept splited full perimeter border specs" do
    property = ODF::Property.new :cell, :border_width => '0.025in',
                                        :border_color => '#000000',
                                        :border_style => 'solid'

    Hpricot(property.xml).at('//style:table-cell-properties')['fo:border'].
      should == "0.025in solid #000000"
  end

  it "should use the first value for vertical and second for horizontal border side specs" do
    property = ODF::Property.new :cell, :border_width => '0.025in 0.3in',
                                        :border_color => '#ff0000 #0000ff',
                                        :border_style => 'solid'

    elem= Hpricot(property.xml).at('//style:table-cell-properties')
    elem['fo:border-top'].should == "0.025in solid #ff0000"
    elem['fo:border-right'].should == "0.3in solid #0000ff"
    elem['fo:border-bottom'].should == "0.025in solid #ff0000"
    elem['fo:border-left'].should == "0.3in solid #0000ff"
  end

  it "should use the third value for bottom border specs when present" do
    property = ODF::Property.new :cell, :border_width => '0.025in 0.3in 0.4in',
                                        :border_color => '#ff0000 #0000ff',
                                        :border_style => 'dotted solid solid'

    elem = Hpricot(property.xml).at('//style:table-cell-properties')
    elem['fo:border-bottom'].should == "0.4in solid #ff0000"

    property = ODF::Property.new :cell, :border_width => '0.025in',
                                        :border_color => '#ff0000 #0000ff #00ff00',
                                        :border_style => 'dotted solid'

    elem = Hpricot(property.xml).at('//style:table-cell-properties')
    elem['fo:border-bottom'].should == "0.025in dotted #00ff00"
  end

  it "should cascade left border specs from fourth to second to first" do
    property = ODF::Property.new :cell, :border_width => '0.1in 0.2in 0.3in 0.4in',
                                        :border_color => '#ff0000 #0000ff #00ff00',
                                        :border_style => 'dotted solid'

    elem = Hpricot(property.xml).at('//style:table-cell-properties')
    elem['fo:border-left'].should == "0.4in solid #0000ff"

    property = ODF::Property.new :cell, :border_width => '0.1in 0.2in 0.3in',
                                        :border_color => '#ff0000 #0000ff',
                                        :border_style => 'dotted'

    elem = Hpricot(property.xml).at('//style:table-cell-properties')
    elem['fo:border-left'].should == "0.2in dotted #0000ff"

    property = ODF::Property.new :cell, :border_width => '0.1in 0.2in',
                                        :border_color => '#ff0000',
                                        :border_style => 'dotted solid dashed double'

    elem = Hpricot(property.xml).at('//style:table-cell-properties')
    elem['fo:border-left'].should == "0.2in double #ff0000"

    property = ODF::Property.new :cell, :border_width => '0.1in',
                                        :border_color => '#ff0000 #0000ff #00ff00 #ffff00',
                                        :border_style => 'dotted solid dashed'

    elem = Hpricot(property.xml).at('//style:table-cell-properties')
    elem['fo:border-left'].should == "0.1in solid #ffff00"
  end

  it "should support paragraph properties" do
    ODF::Property.new(:paragraph).xml.
      should have_tag('style:paragraph-properties')
  end

  it "should know the namespace for style:text-properties style properties" do
    #see http://docs.oasis-open.org/office/v1.2/os/OpenDocument-v1.2-os-part1.html#__RefHeading__1416402_253892949
    ['country-asian', 'country-complex', 'font-charset', 'font-charset-asian',
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
     'text-underline-style', 'text-underline-type', 'text-underline-width', 'use-window-font-color'].
    each do |prop|
      ODF::Property.lookup_namespace_for(prop).should == 'style'
    end
  end

  it "should know the namespace for style:table-cell-properties style properties" do
    #see http://docs.oasis-open.org/office/v1.2/os/OpenDocument-v1.2-os-part1.html#__RefHeading__1416518_253892949
    ['border-line-width', 'border-line-width-bottom', 'border-line-width-left',
     'border-line-width-right', 'border-line-width-top', 'cell-protect', 'decimal-places',
     'diagonal-bl-tr', 'diagonal-bl-tr-widths', 'diagonal-tl-br', 'diagonal-tl-br-widths',
     'direction', 'glyph-orientation-vertical', 'print-content', 'repeat-content',
     'rotation-align', 'rotation-angle', 'shadow', 'shrink-to-fit', 'text-align-source',
     'vertical-align', 'writing-mode'].
    each do |prop|
      ODF::Property.lookup_namespace_for(prop).should == 'style'
    end
  end

  it "should know the namespace for style:table-cell-properties style properties" do
    #see http://docs.oasis-open.org/office/v1.2/os/opendocument-v1.2-os-part1.html#__refheading__1416516_253892949
    ['min-row-height', 'row-height', 'use-optimal-row-height'].each do |prop|
      ODF::Property.lookup_namespace_for(prop).should == 'style'
    end
  end

  it "should know the namespace for style:table-row-properties style properties" do
    # see http://docs.oasis-open.org/office/v1.2/os/OpenDocument-v1.2-os-part1.html#__RefHeading__1416514_253892949
    ['column-width', 'rel-column-width', 'use-optimal-column-width'].each do |prop|
      ODF::Property.lookup_namespace_for(prop).should == 'style'
    end
  end

  it "should know the namespace for style:paragraph-properties style properties" do
    # see http://docs.oasis-open.org/office/v1.2/os/OpenDocument-v1.2-os-part1.html#__RefHeading__1416494_253892949
    ['auto-text-indent', 'background-transparency', 'border-line-width', 'border-line-width-bottom',
     'border-line-width-left', 'border-line-width-right', 'border-line-width-top',
     'font-independent-line-spacing', 'join-border', 'justify-single-word', 'line-break',
     'line-height-at-least', 'line-spacing', 'page-number', 'punctuation-wrap', 'register-true',
     'shadow', 'snap-to-layout-grid', 'tab-stop-distance', 'text-autospace', 'vertical-align',
     'writing-mode', 'writing-mode-automatic'].
    each do |prop|
      ODF::Property.lookup_namespace_for(prop).should == 'style'
    end
  end
end

