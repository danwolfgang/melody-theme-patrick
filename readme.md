# Patrick, a theme framework for Melody

Patrick is a theme for Melody, sure, but it's also more than that. With nearly
100 Theme Options, infinite color schemes, and "callback" fields, Patrick is a
flexible theme framework that makes it easy to create a unique site from this
one design.

* Integration with [Pictaculous](http://pictaculous.com) to create a unique
  color palette. Within Theme Options > Color Palette, supply an image URL to
  the Source Image tab of the Pictaculous Palette field. Select an extracted
  palette then assign palette colors to named locations of the theme, creating
  a unique look for your blog.

* Further individualize your site with fonts from the [Google Web Fonts
  directory](http://www.google.com/webfonts). In Theme Options > Design you
  can select a different typeface (the font name), variation (regular, bold,
  italic, bold italic), and size for the body text and headings.

* A variety of design options to help individualize your blog: one, two, and
  three column layouts; control element transparency; Entry and Page meta
  display position; and home page carousel (with the jQuery Carousel plugin).

* Facebook and Twitter integration. Facebook Commenting, Like button, and
  Recommendations social plugins along with Open Graph meta are included. The
  Twitter retweet button is also included.


# Prerequisites

Patrick requires [Melody](http://openmelody.org) 1.0 or greater. It is not
compatible with Movable Type.

This theme publishes some templates through the Publish Queue, so you'll want
to have
[`run-periodic-tasks`](http://www.movabletype.org/documentation/administrator/setting-up-run-periodic-taskspl.html)
configured and running.

## Plugins

* [Config
  Assistant](https://github.com/openmelody/mt-plugin-config-assistant/downloads)
  version 2.2.2 or greater (note that this version is newer than what comes 
  with Melody 1.0.2)

### Optional

The following plugins are not required, but are useful plugins that I use
to run [danandsherree.com](http://danandsherree.com).

* [Custom CSS](https://github.com/endevver/mt-plugin-customcss/downloads)
* [Default
  Category](https://github.com/danwolfgang/mt-plugin-default-category/downloads)
* [Hot Date](https://github.com/danwolfgang/mt-plugin-hot-date/downloads)
* [Image Asset from
  Entry](https://github.com/danwolfgang/melody-plugin-image-asset-from-entry/downloads)
* [PQ Manager](https://github.com/endevver/mt-plugin-pqmanager/downloads)
* [Wordometer](https://github.com/danwolfgang/mt-plugin-wordometer/downloads)


# Installation

The Patrick theme is installed just like any other plugin in Melody. The [Easy
Plugin Installation Guide][] provides detailed installation instructions.

[Easy Plugin Installation Guide]:
    https://github.com/openmelody/melody/wiki/install-EasyPluginInstallGuide

# Use

Once Patrick is installed, create a new blog or assign the theme to an
existing blog.

Patrick has many, many Theme Options. Refer to the Theme Documentation (found
in Theme Dashboard > Documentation) for details of the options and how they
interact with each other.


# Designer and Developer Options

Patrick includes some new config types for Config Assistant that other theme
designers and developers can use. The following is information for developers
only; users of the theme don't need to worry about the details below. The
Patrick theme introduces two new Config Types:

* `pictaculous`: Uses the [Pictaculous](http://pictaculous.com) service to
  create color palettes from a user-selected image. The user can then select a
  color palette from the returned palettes, then they can order the colors to
  customize a theme.

* `font`: Users can select the typeface, size, and variation of a font (or any
  of those three options) from a predefined list.

Examples of these config types are shown below. Of course, you can also
investigate this theme's `config.yaml` to see these in action.

## `pictaculous`

The `pictaculous` config type creates a field with three tabs of options:

* Source Image: provides a text field where the user can paste the URL to an
  image.

* Choose Palette: after specifying a URL to get colors, the found palettes are
  displayed. Here the user can select which palette they want to work with.

* Order Colors: the selected color palette can be "mapped" to any named
  options to apply the colors from that palette. The user can simply drag and
  drop colors to create a unique look for their site.

A `pictaculous` field is created similar to how any other field is created:

    color_palette_field:
        label: 'Pictaculous Palette'
        hint: 'Use the Pictaculous service to create a color palette from the image listed here.'
        type: pictaculous
        color_names: 'Background,Header,Column Background,Accent'
        default_colors: '#FFFFFF, #000000'
        tag: Pictaculous

The `color_names` key is unique to the `pictaculous` field type. This key
should contain a comma-separated list of the named options a user can apply
colors to, and are displayed in the Order Colors tab. A color palette from
Pictaculous will provide five colors; `color_names` can contain any number of
values, giving the user a chance to re-use colors, for example.

The `default_colors` key gives you an opportunity to supply some colors that
the user may find useful, regardless of the colors found in the color palette
they select. Obvious choices are black (#000000) and white (#ffffff).

To publish this field's contents, notice that the tag has been appended with
`Palette`, which gives access to the named colors found in a palette. The
named colors are "dirified," which means they are changed into something more
"computer readable": non-word/space characters are removed, spaces are changed
to underscores, and the entire string is converted to lower-case, as in the
following example:

    <mt:PictaculousPalette>
        Background: <mt:Var name="background">
        Header: <mt:Var name="header">
        Column Background: <mt:Var name="column_background">
        Accent: <mt:Var name="accent">
    </mt:PictaculousPalette>

Each variable outputs a hex value with a leading "#," such as "#eba56a." If
the user has not explicitly set a value, then white ("#ffffff") is output.

Alternatively, RGB values can be output using the `format` attribute, as in
the example below. Valid values are `rgb` and `hex`.

    <mt:PictaculousPalette format="rgb">
        Background: <mt:Var name="background">
    </mt:PictaculousPalette>

When outputting RGB values, a comma-separated list is published (as in
`123,123,123`). This makes it easy to include alpha transparency values if
required.

## `font`

Specify `font` as the field type. You will also need to specify three other
keys: `typefaces`, `sizes`, and `variations`, each of which contains a
comma-delimited list of values. This field is actually storing the data as
JSON. You can supply defaults, but you'll need to carefully craft the JSON
default text (note the escaped quotes).

    body_text:
        label: 'Body Text Font'
        hint: 'Select a typeface and variation to use for body text.'
        type: font
        typefaces: 'Arial, Georgia, Tahoma, Verdana'
        sizes: '14,15,16,17,18,19,20,21,22,23,24,25,26,27,28'
        variations: 'Regular, Bold, Italic, Bold Italic'
        preview: 1
        default: '"[{\"typeface\":\"Tahoma\",\"size\":\"15\",\"variation\":\"Regular\"}]"'
        tag: BodyText

Note that any combination of `typefaces`, `sizes`, and `variations` may be
used. If you want to give your user the ability to adjust only the `typeface`
and `variation`, for example, simply do not supply the `size` key.

The `preview` key is optional; include it to show a preview of the font
selection. Note that the preview relies upon the selected font being available
to the user.

To publish the selected values, use the field's tag followed by `Font`, as in
the following example:

    <mt:BodyTextFont><mt:Var name="typeface"> <mt:Var name="size"> <mt:Var name="variation"></mt:BodyTextFont>


# License

This plugin is licensed under the same terms as Perl itself.

# Copyright

Copyright 2010-2011 by [Dan Wolfgang](http://danandsherree.com). All rights
reserved.
