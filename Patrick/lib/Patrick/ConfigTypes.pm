package Patrick::ConfigTypes;

use MT::Util qw( encode_html dirify );
use ConfigAssistant::Util qw( find_theme_plugin );

use Data::Dumper;

use strict;
use warnings;

sub init_app {
    my $plugin = shift;
    my ($app) = @_;
    return if $app->id eq 'wizard';

    my $r = $plugin->registry;
    #my $tags = _load_tags( $app, $plugin );
    # If any tags were needed, merge them into the registry.
    #if ( ref($tags) eq 'HASH' ) {
    #    MT::__merge_hash($r->{tags}, $tags);
    #}
    $r->{tags} = sub { _load_tags( $app, $plugin ) };
}
 
sub _load_tags {
    my $app  = shift;
    my $tags = {};
 
    for my $sig ( keys %MT::Plugins ) {
        my $plugin = $MT::Plugins{$sig};
        my $obj    = $MT::Plugins{$sig}{object};
        my $r      = $obj->{registry};

        # First initialize all the tags associated with themes
        my @sets = keys %{ $r->{'template_sets'} };
        foreach my $set (@sets) {
            if ( $obj->registry( 'template_sets', $set, 'options' ) ) {
                foreach my $opt (
                    keys %{ $obj->registry( 'template_sets', $set, 'options' )
                    } )
                {
                    my $option
                      = $obj->registry( 'template_sets', $set, 'options',
                                        $opt );

                    # If the option does not define a tag name, then there 
                    # is no need to register one
                    next if ( !defined( $option->{tag} ) );
                    my $tag = $option->{tag};

                    # Only create the ...Palette tag for Pictaculous config types.
                    if ( $option->{type} eq 'pictaculous' ) {
                        $tags->{block}->{$tag . 'Palette'} = sub {
                            my ( $ctx, $args, $cond ) = @_;

                            my $blog = $ctx->stash('blog');
                            my $bset = $blog->template_set;
                            $ctx->stash( 'field', $bset . '_' . $opt );
                            $ctx->stash( 'plugin_ns', find_theme_plugin($bset)->id );

                            use ConfigAssistant::Plugin;
                            my $value = ConfigAssistant::Plugin::_get_field_value($ctx);
                            $value = '"[]"' if ( !$value || $value eq '' );
                            eval "\$value = \"$value\"";
                            if ($@) { $value = '[]'; }
                            my $list = JSON::from_json($value);

                            # The color_names were specified by the designer.
                            # These names need to be made available in 
                            # templates. The user should have already assigned
                            # colors (from a palette) to the color_names, 
                            # but if not just fall back to white ('#ffffff).
                            my @color_names = split(',', $option->{color_names});
                            if (@color_names) {
                                # Grab the ordered colors that the user picked.
                                # If no ordered colors were saved, just use a
                                # bunch of white as a fall-back.
                                my $palette = eval { @$list[0]->{'ordered'} }
                                    ? @$list[0]->{'ordered'}
                                    : '#ffffff,#ffffff,#ffffff,#ffffff,#ffffff';
                                my @color_values = split(',', $palette);

                                my $vars  = $ctx->{__stash}{vars};
                                foreach my $color_name (@color_names) {
                                    $color_name = dirify($color_name);

                                    my $color_value = lc(shift @color_values)
                                        || '#ffffff'; # Fallback to white
                                    $vars->{$color_name} = $color_value;
                                }

                                defined( my $out .= $ctx->slurp( $args, $cond ) ) or return;

                                return $out;
                            }
                            else {
                                MT->log({
                                    blog_id => $blog->id,
                                    info    => 'warning',
                                    message => 'The Pictaculous config type has not had any color_names defined.',
                                });
                            }
                        };
                    }

                    if ( $option->{type} eq 'font' ) {
                        $tags->{block}->{$tag . 'Font'} = sub {
                            my ( $ctx, $args, $cond ) = @_;

                            my $blog = $ctx->stash('blog');
                            my $bset = $blog->template_set;
                            $ctx->stash( 'field', $bset . '_' . $opt );
                            $ctx->stash( 'plugin_ns', find_theme_plugin($bset)->id );

                            use ConfigAssistant::Plugin;
                            my $value = ConfigAssistant::Plugin::_get_field_value($ctx);
                            $value = '"[]"' if ( !$value || $value eq '' );
                            eval "\$value = \"$value\"";
                            if ($@) { $value = '[]'; }
                            my $list = JSON::from_json($value);

                            if ($list) {
                                my $out   = '';
                                my $vars  = $ctx->{__stash}{vars};

                                $vars->{'typeface'}  = @$list[0]->{typeface};
                                $vars->{'size'}      = @$list[0]->{size};
                                $vars->{'variation'} = @$list[0]->{variation};

                                defined( $out .= $ctx->slurp( $args, $cond ) )
                                    or return;

                                return $out;
                            }
                        };
                    }
                } ## end foreach my $opt ( keys %{ $obj...})
            } ## end if ( $obj->registry( 'template_sets'...))
        } ## end foreach my $set (@sets)

    }
    return $tags;
}

# The font config type will generate typeface, size, and/or variation 
# drop-down selectors for the user to work with.
sub font_selector {
    my $app = shift;
    my $ctx = shift;
    my ($field_id, $field, $value) = @_;
    my $out;

    # Gather the options.
    my @typefaces  = split(',', $field->{typefaces} );
    my @sizes      = split(',', $field->{sizes}     );
    my @variations = split(',', $field->{variations});
    
    # Trim any leading/trailing whitespace
    @typefaces  = _trim_whitespace(@typefaces);
    @sizes      = _trim_whitespace(@sizes);
    @variations = _trim_whitespace(@variations);

    # Create the typeface, size, and variation drop-down selectors. It's
    # possible that any combination of one, two, or all three of these are
    # supposed to be displayed.
    if (@typefaces) {
        $out .= "<select name=\"$field_id-typefaces\" "
            . "id=\"$field_id-typefaces\">\n";
        foreach my $typeface (@typefaces) {
            $out .= "\t<option value=\"$typeface\""
                . ">$typeface</option>\n";
        }
        $out .= "</select>\n";
    }
    if (@sizes) {
        $out .= "<select name=\"$field_id-sizes\" "
            . "id=\"$field_id-sizes\">\n";
        foreach my $size (@sizes) {
            $out .= "\t<option value=\"$size\""
                . ">$size</option>\n";
        }
        $out .= "</select>\n";
    }
    if (@variations) {
        $out .= "<select name=\"$field_id-variations\" "
            . "id=\"$field_id-variations\">\n";
        foreach my $variation (@variations) {
            $out .= "\t<option value=\"$variation\""
                . ">$variation</option>\n";
        }
        $out .= "</select>\n";
    }

    # Now we need to display the hidden field that contains the saved value.
    # Use the encode_html function to ensure that values are encoded, and
    # the additional "1" will escape HTML entities.
    $out .= "<textarea id=\"$field_id\" name=\"$field_id\" class=\"full-width hidden\">$value</textarea>\n";

    # And now we need to include the Javascript that will keep the hidden field up-to-date.
    $out .= <<END;
<script type="text/javascript">
\$(document).ready( function() {
    // When the page is loaded, use the hidden field value (a JSON object)
    // to populate the font fields.
    // Eval once to un-escape quotes
    var json = eval( '"' + \$('#$field_id').val() + '"' );
    // Eval a second time to turn into an object.
    json = eval(json);

    if ( \$('#$field_id-typefaces') ) {
        \$('#$field_id-typefaces').val( json[0].typeface );
    }
    if ( \$('#$field_id-sizes') ) {
        \$('#$field_id-sizes').val( json[0].size );
    }
    if ( \$('#$field_id-variations') ) {
        \$('#$field_id-variations').val( json[0].variation );
    }

    // When a field is clicked, update the hidden field.
    \$('#$field_id-typefaces, #$field_id-sizes,#$field_id-variations').click(function() {
        // Set the variables. Even if one of them ends up empty because it's
        // not used, that's ok because just declaring them will make
        // everything work.
        var t; // typeface
        var s; // size
        var v; // variation
        
        // Grab the selected value and save it to the specified variable.
        if ( \$('#$field_id-typefaces') )
            t = \$('#$field_id-typefaces').val();
        if ( \$('#$field_id-sizes') )
            s = \$('#$field_id-sizes').val();
        if ( \$('#$field_id-variations') )
            v = \$('#$field_id-variations').val();

        // Turn the saved variables into a JSON object.
        var font = new Array();
        font.push( { 'typeface': t, 'size': s, 'variation': v } );

        // Convert that JSON object into a string so that it can be saved.
        var json = font.toJSON().escapeJS();
        \$('#$field_id').val( json );
    });
});
</script>
END

    return $out;
}

sub _trim_whitespace {
    # Trim any leading or trailing whitespace. An array or string can be
    # passed to _trim_whitespace. If an array, all elements are trimmed.
    my @out = @_;
    for (@out) {
        s/^\s+//; # Trim from the start of the string
        s/\s+$//; # Trim from the end of the string
    }
    return @out == 1 ? $out[0] : @out;
}

# Use the pictaculous.com API to build a color palette from a selected
# image. Then return all of the color pallete results and let the user pick
# which palette they want to use for their site.
sub pictaculous {
    my $app = shift;
    my $ctx = shift;
    my ($field_id, $field, $value) = @_;
    my $out;

    my $static = $app->static_path;
    my $url    = $app->mt_uri . '?__mode=pictaculous_ajax&image=';

    # Create the navigation options for the field. Organizing into "panels"
    # keeps the field contents manageable.
    $out .= "<div id=\"$field_id-nav\">\n";
    $out .= "   <ul>\n";
    $out .= "       <li id=\"$field_id-image-nav\" style=\"display: inline; padding: 5px 5px 6px; border: 1px solid #dfecf2; border-bottom: 1px solid #fff; background: #fff; cursor: pointer;\">Source Image</li>\n";
    $out .= "       <li id=\"$field_id-palette-nav\" style=\"display: inline; padding: 5px 5px 6px; border: 1px solid #dfecf2; background: #dfecf2; cursor: pointer;\">Choose Palette</li>\n";
    $out .= "       <li id=\"$field_id-colors-nav\" style=\"display: inline; padding: 5px 5px 6px; border: 1px solid #dfecf2; background: #dfecf2; cursor: pointer;\">Order Colors</li>\n";
    $out .= "   </ul>\n";
    $out .= "</div>\n";
    
    $out .= "<div id=\"$field_id-container\" style=\"margin-top: 5px; padding: 0px 10px 8px; border: 1px solid #dfecf2; background: #fff;\">\n";
    # Create a text field where the URL to an image can reside. This is the
    # image used to build the color palette. The value is filled in from the
    # $value field with the big object with all of the palettes.
    $out .= "    <div id=\"$field_id-image-nav-container\">\n";
    $out .= "        <h4>Specify a Source Image</strong></h4>\n";
    $out .= "        <label for=\"$field_id-image\">Enter the URL of an image to create color palette options, then click &ldquo;get palettes from this image.&rdquo;</label>\n";
    $out .= "        <input type=\"text\" id=\"$field_id-image\" name=\"$field_id-image\" class=\"full-width\" style=\"width: 580px\" />\n";
    $out .= "        <div style=\" height: 20px;\" id=\"$field_id-actions\"><a href=\"javascript:void(0)\" id=\"$field_id-get-palette\">Get palettes from this image</a> <span id=\"$field_id-spinner\" class=\"hidden\" style=\"vertical-align: middle;\"><img src=\"" . $static . "images/indicator.white.gif\" width=\"16\" height=\"16\" /></span></div>\n";
    $out .= "        <div id=\"$field_id-image-status\"></div>\n";
    $out .= "    </div>\n";

    # Show the resulting palettes
    $out .= "    <div id=\"$field_id-palette-nav-container\" class=\"hidden\">";
    $out .= "        <h4>Available Color Palettes</h4>";
    $out .= "        <p>Mouse over colors to see the hex color value.</p>";
    $out .= "        <p>After selecting a color palette click over to Order Colors to sort the palette.</p>";
    $out .= "        <div id=\"$field_id-palette-result\">No palettes are available. Specify a source image to get started.</div>";
    $out .= "    </div>";

    # Show the selected palette. At some point, the user will be able to 
    # drag-drop to organize the colors however they like.
    $out .= "    <div id=\"$field_id-colors-nav-container\" class=\"hidden\">";
    $out .= "        <h4>Order this Color Palette</h4>";
    $out .= "        <p>Drag and drop the colors in this palette to use them.</p>";
    $out .= "        <div id=\"$field_id-colors-result\">";

    # The color_names key lets a designer designate how a user can apply a 
    # color to the site.
    my $color_names = $field->{color_names};
    if ($color_names) {
        my @names = split(/,\s*/, $color_names);
        $out .= "<div id=\"$field_id-color-names\" style=\"text-align: center;\">";
        foreach my $name (@names) {
            my $dirified_name = dirify($name);
            $out .= "<span class=\"$dirified_name\" style=\"display: inline-block; padding: 0 10px 20px;\">";
            $out .= "    <span class=\"label\">$name</span>";
            $out .= "    <div style=\"margin: 0 auto; width: 50px; height: 50px; border: 1px solid #eee;\"></div>";
            $out .= "</span>";
        }
        $out .= "</div>";
    }
    
    $out .= "            <div id=\"$field_id-selected-palette\" style=\"margin-top: 10px; padding-top: 10px; border-top: 1px solid #ddd; text-align: center;\">No palettes are available. Specify a source image and choose a palette to get started.</div>";

    # Close the $field_id-colors-result div
    $out .= "        </div>";
    # Close the $field_id-colors-nav-container div
    $out .= "    </div>";

    # Close the $field_id-container
    $out .= "</div>";
    
    # Set $value to '' just to avoid a message in the debug log.
    $value = '' unless $value;

    # Save the image URL, and resulting palettes. This is where the JSON
    # object is read from and written to.
    $out .= "<textarea id=\"$field_id\" name=\"$field_id\" class=\"full-width hidden\">$value</textarea>";

    # Include the jQuery UI javascript
    $out .= '<script src="' . $static . 'support/plugins/patrick/ui'
        . '/minified/jquery.ui.core.min.js"></script>';
    $out .= '<script src="' . $static . 'support/plugins/patrick/ui'
        . '/minified/jquery.ui.widget.min.js"></script>';
    $out .= '<script src="' . $static . 'support/plugins/patrick/ui'
        . '/minified/jquery.ui.mouse.min.js"></script>';
    $out .= '<script src="' . $static . 'support/plugins/patrick/ui'
        . '/minified/jquery.ui.draggable.min.js"></script>';
    $out .= '<script src="' . $static . 'support/plugins/patrick/ui'
        . '/minified/jquery.ui.droppable.min.js"></script>';

    $out .= <<END;
<script type="text/javascript">
\$(document).ready( function() {
    // When the page is loaded, use the hidden field value (a JSON object)
    // to populate the palette fields.

    // Eval once to un-escape quotes
    var json = eval( '"' + \$('#$field_id').val() + '"' );
    // Eval a second time to turn into an object.
    json = eval(json);


    // The field has been previously used, so there is data to parse.
    if (json) {
        // Set the Image field with the URL of the selected image.
        \$('#$field_id-image').val( json[0].image );

        // Add a View Image link so the user can see the original to compare
        // to the colors that were found.
        var view_link = '<div style=\"float: right;\"><a href=\"' 
            + json[0].image 
            + '\" target=\"_blank\">View image</a></div>';
        view_link = \$(view_link);
        \$('#$field_id-actions').append(view_link);

        // Creat the palette options on the Choose Palette tab
        createPalettes();
        
        // If any ordered colors were previously saved, load them.
        if (json[0].ordered) {
            // Break the ordered colors string into an array.
            var ordered_colors = json[0].ordered.split(',');
            
            // Find any of the named color options created by the theme
            // designer. Push the saved ordered color in place.
            \$('#$field_id-color-names span div').each(function() {
                var color = ordered_colors.shift();
                
                // If color is undefined (perhaps if the designer has
                // added new named color options), just set it to white.
                if (color == undefined) {
                    color = '#ffffff';
                }

                // Lastly, set the color.
                \$(this).css('background-color', color);
                \$(this).attr('title', color.toUpperCase());
            });
        }
        
        // Show the correct tab based on the data provided.
        if (json[0].selected) {
            tabbedContent('$field_id-colors-nav')
        }
        else if (json[0].image) {
            tabbedContent('$field_id-palette-nav');
        }
    }

    // When a tab is clicked, show and hide the correct content
    \$('#$field_id-nav li').click(function() {
        var id = \$(this).attr('id');
        tabbedContent(id);
    });

    // If "get palette" is clicked, build the palette options.
    \$('#$field_id-get-palette').click(function() {
        // First check for a supplied image
        if ( !\$('#$field_id-image').val() ) {
            \$('#$field_id-image-status').html(
                '<p style="color: red;">Specify an image URL to proceed.</p>'
            );
            return false;
        }

        // Reset the status indicator.
        \$('#$field_id-image-status').html('');

        var spinner = '$static' + 'images/indicator.white.gif';

        \$('#$field_id-spinner').removeClass('hidden');

        var url = '$url' + encodeURIComponent( \$('#$field_id-image').val() );

        \$.ajax({ 
            url: url,
            success: function(data) {
                // Turn the returned data into a JSON object.
                var data = eval('(' + data + ')');

                // First check to see if the response was an error. If it
                // is an error, warn the user and just give up.
                if (data.status == 'error') {
                    \$('#$field_id-image-status').html(
                        '<p style=\"color: red;\">' + data.error + '</p>'
                    );
                    \$('#$field_id-spinner').addClass('hidden');
                    return false;
                }

                var image = \$('#$field_id-image').val();
                var palettes = new Array();
                palettes.push( { 'image': image, 'data': data } );
                // Convert that JSON object into a string so that it can be saved.
                var json = palettes.toJSON().escapeJS();
                \$('#$field_id').val( json );

                createPalettes();

                // Now that we're done, hide the spinner graphic.
                \$('#$field_id-spinner').addClass('hidden');

                // After getting the palette options, switch to the Choose
                // Palette tab.
                tabbedContent('$field_id-palette-nav');
            },
        });
        
    });
});

function savePaletteData() {
    // Ok, so this doesn't really save a user's palette data. It builds a
    // JSON object, converts it to a string, and writes it to the "master"
    // field that is actually saved.

    // Eval once to un-escape quotes
    var json = eval( '"' + \$('#$field_id').val() + '"' );
    // Eval a second time to turn into an object.
    json = eval(json);

    // Grab the image URL
    json[0].image = \$('#$field_id-image').val();

    // If the palette options have been created, and if a palette has been
    // selected, grab it.
    if ( \$('#$field_id-option') ) {
        json[0].selected = \$('input[name="$field_id-option"]:checked').val();
    }
    
    // If the user has gone to the Order Colors tab and made some selections
    // we want to save those, too.
    if ( \$('#$field_id-color-names') ) {
        // Look at each of the named color options, and use them to build
        // this piece of JSON.
        var ordered = new Array();
        \$('#$field_id-color-names span div').each(function() {
            var value = \$(this).css('background-color');
            if (value == 'transparent') {
                value = '#ffffff';
            }
            else {
                var color = value;
                value = rgb2hex(color);
            }
            ordered.push(value);
        });

        var ordered_str = ordered.join(',');
        json[0].ordered = ordered_str;
    }

    // Convert that JSON object into a string so that it can be saved.
    var json_string = json.toJSON().escapeJS();
    \$('#$field_id').val( json_string );
}

function selectPalette(selected) {
    //The user has chosen a palette. Let's save their selection.
    savePaletteData();
    
    // Push the selected palette over to the Order Colors tab
    createSelectedPalette(selected);
    
    // Reset the named colors in the Order Colors tab. Because the user has
    // picked a new selected palette, we want them to be able to start fresh.
    \$('#$field_id-color-names span div').css('background-color', '#fff');
    
    // After selecting, jump to the Order Colors tab
    tabbedContent('$field_id-colors-nav');
}

function createPalettes() {
    // Remove any existing color palettes by simply clearing the result area.
    \$('#$field_id-palette-result').html('');

    // Eval once to un-escape quotes
    var json = eval( '"' + \$('#$field_id').val() + '"' );
    // Eval a second time to turn into an object.
    json = eval(json);

    var data = json[0].data;

    var palettes = new Array;

    // Grab the color palettes generated by Kuler. Kuler is supplying a 
    // variety of palettes in an array. Go through the array to grab all of 
    // the palettes.
    for (var i = 0; i < data.kuler_themes.length; i++) {
        palettes.push( data.kuler_themes[i].colors );
    }
    
    // Grab the color palettes from Colour Lovers. Color Lovers is also supply
    // a variety of palettes in an array.
    for (var i = 0; i < data.cl_themes.length; i++) {
        palettes.push( data.cl_themes[i].colors );
    }

    // Grab the colors generated by Pictaculous. Put them at the start of
    // the array just because there's only ever one, and I like how that
    // organizes things.
    palettes.unshift( data.info.colors );

    // If a color palette has been previously saved, we want to mark it 
    // as "selected."
    var selected_palette = json[0].selected;
    // Create the selected palette on the Order Colors tab, too.
    if (selected_palette) {
        createSelectedPalette(selected_palette);
    }

    // Each color palette should become a row full of patches of the 
    // returned colors. The user can then select a row as their preferred
    // color palette.
    for (var i = 0; i < palettes.length; i++) {
        // Grab the current color palette
        var palette = palettes[i];
        
        // The color_block variable holds the file colors in each palette.
        var color_block = '';
        for (var c = 0; c < palette.length; c++) {
            // If a white block is found in the palette, delineate it by
            // using a gray background.
            var border = '';
            if (palette[c] == 'FFFFFF') {
                border = '; border: 1px solid #eee';
            }
            color_block += '<span style=\"display: inline-block; '
                + 'width: 50px; height: 50px; background-color: #' 
                + palette[c] + border + ';\" title=\"#' + palette[c] 
                + '\"></span>';
        }

        var checked = '';
        if (selected_palette == palette) {
            checked = ' checked="checked"';
        }

        // Build the row. Included is the radio button, the color_block,
        // and of course wrappers.
        var option = '<div style=\"margin-bottom: 5px;\">'
            + '<label>'
            + '<input type=\"radio\" id=\"$field_id-option\" name=\"$field_id-option\" value=\"' 
                + palette 
                + '\" style=\" float: left; margin: 20px 20px 0 0;\" onClick=\"selectPalette(' 
                + \"'\" + palette + \"'\" 
                + ');\"'
                + checked + ' />' 
            + color_block 
            + '</label>'
            + '</div>';
        
        // Turn this text into an object
        option = \$(option);

        // Ad the new option to the results area!
        \$('#$field_id-palette-result').append( option );
    }
}

function createSelectedPalette(selected_palette) {
    // Create the selected palette, to be displayed on the Order Colors tab.
    // Start by turning the selected_palette string into an array.
    var palette = new Array();
    palette = selected_palette.split(',');
    
    // Add a white option, just because it's so useful.
    palette.push('FFFFFF');

    // The color_block variable holds the file colors in each palette.
    var color_block = '';
    for (var c = 0; c < palette.length; c++) {
        // If a white block is found in the palette, delineate it by
        // using a gray background.
        var border = '';
        if (palette[c] == 'FFFFFF') {
            border = '; border: 1px solid #eee';
        }
        color_block += '<span style=\"display: inline-block; '
            + 'margin: 0 10px; width: 50px; height: 50px; '
            + 'background-color: #' + palette[c] + border 
            + ';\" title=\"#' + palette[c] + '\"></span>';
    }

    // Add this new block of colors from the selected palette to the Order
    // Colors tab.
    \$('#$field_id-selected-palette').html('<p>Your selected palette</p>' + color_block);

    // Now that the colors have been added, turn them into "draggables."
    \$("#$field_id-selected-palette span").draggable({ 
        containment: "#$field_id-colors-result", 
        helper:      "clone", 
        revert:      true, 
        scroll:      false
    });

    // ...And now that the draggable colors have been created, bind them
    // to the "droppable" color options.
    \$("#$field_id-color-names span div").droppable({
        accept:    "#$field_id-selected-palette span",
        tolerance: 'touch',
        drop:      function( event, ui ) {
            var color = ui.draggable.attr('title');
            \$(this).css('background-color', color);
            \$(this).attr('title', color);
            savePaletteData();
        }
    });
}

// When reading the background color of the ordered colors, the RGB value
// is returned. The following is used to convert that into a hex color,
// which is what we want to work with.
var hexDigits = new Array
        ("0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f");

function rgb2hex(rgb) {
    rgb = rgb.match(/^rgb\\((\\d+),\\s*(\\d+),\\s*(\\d+)\\)\$/);
    return "#" + hex(rgb[1]) + hex(rgb[2]) + hex(rgb[3]);
}

function hex(x) {
    return isNaN(x) ? "00" : hexDigits[(x - x % 16) / 16] + hexDigits[x % 16];
}

function tabbedContent(id) {
    // Use the tabs to display the appropriate content. Update the tab's
    // border and background, and display the appropriate container.
    // Show the appropriate container
    \$('#$field_id-container > div').each(function() {
        \$(this).addClass('hidden');
    })
    \$('#'+id+'-container').removeClass('hidden');
    
    // Update the tabs display
    \$('#$field_id-nav li').each(function() {
        \$(this).css('border-bottom', '1px solid #dfecf2');
        \$(this).css('background',    '#dfecf2');
    });
    \$('#'+id).css('border-bottom', '1px solid #fff');
    \$('#'+id).css('background',    '#fff');
}
</script>
END
    return $out;
}

sub pictaculous_ajax {
    my ($app) = shift;
    my $q = $app->query;
    
    # Give up if no image was specified.
    if ( !$q->param('image') ) {
        return '<p>Select an image before proceeding.</p>';
    }

    # Get the image data. Pictaculous should receive *data*, not the URL
    # to an image.
    use LWP::Simple;
    my $image_data = LWP::Simple::get($q->param('image'));

    # Use a POST request to talk to Pictaculous.
    use  HTTP::Request::Common qw(POST);
    use LWP::UserAgent;
    my $ua = LWP::UserAgent->new;

    my $req = POST 'http://pictaculous.com/api/1.0/',
                  [ image => $image_data ];

    # A JSON object is returned from Pictaculous. Grab the _content key.
    my $result = $ua->request($req)->{'_content'};

    return $result;
}

1;
