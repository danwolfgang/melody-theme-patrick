# Patrick, a theme framework for Melody



# Prerequisites

## Plugins

* Facebook Commenters

# Designer and Developer Options

Patrick includes some new config types for Config Assistant that other theme designers can use. The Patrick theme introduces two new Config Types:

* `pictaculous`: Uses the [Pictaculous](http://pictaculous.com) service to create color palettes from a user-selected image. The user can then select a color palette from the returned palettes, then they can order the colors to customize a theme.
* `font`: Users can select the typeface, size, and variation of a font (or any of those three options) from a predefined list.

Examples of these config types are shown below. Of course, you can also investigate this theme's `config.yaml` to see these in action.

## `pictaculous`

The `pictaculous` config type creates a field with three tabs of options:

* Source Image: provides a text field where the user can paste the URL to an image.
* Choose Palette: after specifying a URL to get colors, the found palettes are displayed. Here the user can select which palette they want to work with.
* Order Colors: the selected color palette can be "mapped" to any named options to apply the colors from that palette. The user can simply drag and drop colors to create a unique look for their site.

A `pictaculous` field is created similar to how any other field is created:

    color_palette_field:
        label: 'Pictaculous Palette'
        hint: 'Use the Pictaculous service to create a color palette from the image listed here.'
        type: pictaculous
        color_names: 'Background,Header,Column Background,Accent'
        tag: Pictaculous

The `color_names` key is unique to the `pictaculous` field type. This key should contain a comma-separated list of the named options a user can apply colors to, and are displayed in the Order Colors tab. A color palette from Pictaculous will provide five colors; `color_names` can contain any number of values, giving the user a chance to re-use colors, for example.

To publish this field's contents, notice that the tag has been appended with `Palette`, which gives access to the named colors found in a palette. The named colors are "dirified," which means they are changed into something more "computer readable": non-word/space characters are removed, spaces are changed to underscores, and the entire string is converted to lower-case, as in the following example:

    <mt:PictaculousPalette>
        Background: <mt:Var name="background">
        Header: <mt:Var name="header">
        Column Background: <mt:Var name="column_background">
        Accent: <mt:Var name="accent">
    </mt:PictaculousPalette>

Each variable outputs a hex value with a leading "#," such as "#eba56a." If the user has not explicitly set a value, then white ("#ffffff") is output.


## `font`

Specify `font` as the field type. You will also need to specify three other keys: `typefaces`, `sizes`, and `variations`, each of which contains a comma-delimited list of values. This field is actually storing the data as JSON. You can supply defaults, but you'll need to carefully craft the JSON default text (note the escaped quotes).

    body_text:
        label: 'Body Text Font'
        hint: 'Select a typeface and variation to use for body text.'
        type: font
        typefaces: 'Arial, Georgia, Tahoma, Verdana'
        sizes: '14,15,16,17,18,19,20,21,22,23,24,25,26,27,28'
        variations: 'Regular, Bold, Italic, Bold Italic'
        default: '"[{\"typeface\":\"Tahoma\",\"size\":\"15\",\"variation\":\"Regular\"}]"'
        tag: BodyText

Note that any combination of `typefaces`, `sizes`, and `variations` may be used. If you want to give your user the chance to adjust only the `typeface` and `variation`, for example, simply do not supply the `size` key.

To publish the selected values, use the field's tag followed by `Font`, as in the following example:

    <mt:BodyTextFont><mt:Var name="typeface"> <mt:Var name="size"> <mt:Var name="variation"></mt:BodyTextFont>

