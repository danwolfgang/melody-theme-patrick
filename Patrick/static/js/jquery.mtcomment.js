/*
 * jQuery Commenting Plugin for Movable Type
 */
(function($){
    $.fn.ajaxSubmit.debug = true;
    $.fn.commentForm = function(options) {
        var defaults = {
            speed: 'slow',
            entryId: 0,
            parentId: 0,
            leaveCommentMsg: 'Leave a comment...',
            insertMethod: 'append',
            replySelector: 'a.reply',
            onSuccess: null,
            wrapClass: null,
            loggedInClass: null,
            loggedOutClass: null,
            responseDataType: 'text',
            target: '#comments-list'
        };
        var settings = $.extend( {}, defaults, options);
        var source; var fi; var fo;
        this.each(function() {
            source = $(this);
            if (settings.loggedInClass) {
                fi = $(this).find(settings.loggedInClass);
                $(fi).onauthchange( function(e, u) { 
                    if (u.is_authenticated) $(this).show();
                    else $(this).hide();
                });
            } else {
                fi = $(this);
            }
            if (settings.loggedOutClass) {
                fo = $(this).find(settings.loggedOutClass);
                $(fo).onauthchange( function(e, u) { 
                    if (!u.is_authenticated) $(this).show();
                    else $(this).hide();
                });
            }
            
            var id = fi.attr('id');
            var action = fi.attr('action');
            var method = fi.attr('method');
            var entry_id = $('[name=entry_id]').val();
            
            // TODO - bail if no entry_id specified?
            if (!entry_id) entry_id = settings.entryId;
            
            // initialize the overlay
            // TODO - only initialize if spinner class is not present
            fi.append('<div class="spinner"></div><div class="spinner-status"></div>');
            
            // clear focus event, and initialize the 'Leave a comment...' message
            fi.find('textarea').unbind('focus').val(settings.leaveCommentMsg).focus( function() { 
                if($(this).val() == settings.leaveCommentMsg) { $(this).val(''); } 
            });
            // for now, let's kill the preview button
            // in the future this will only happen when live previews are activated
            fi.find('input.comment-preview').hide();
            // clear any submit events, so we can make our own
            //fi.unbind('submit');
            
            // Bind auth/unauthed handlers
            /*
            // TODO
            // if user is logged IN then proceed as usual
            // but if user is logged OUT then execute the logged out callback
            // Logged out callback should
            // a) replace the comment form with a login form?
            // b) show and hide content?
            */
            
            // Bind a submit handler to the form.
            fi.submit( function(e){
                var form = $(this);
                $(this).find('[name=ajax]').val('1');
                $(this).find('[name=entry_id]').val(entry_id);
                $(this).find('[name=preview]').val('0');
                $(this).find('[name=parent_id]').val(settings.parentId);
                $(this).find('[name=armor]').val(mt.blog.comments.armor);
                var spinner_selector = '.spinner, .spinner-status';
                var success_handler = function(responseText) {
                };
                var submit_options = {
                    contentType: 'application/x-www-form-urlencoded; charset=utf-8',
                    iframe: false,
                    type: 'post',
                    dataType: settings.responseDataType,
                    clearForm: true,
                    beforeSubmit: function(formData, jqForm, options) {
                        var queryString = $.param(formData); // for debugging
                        fi.find(spinner_selector).fadeIn('fast').css('height',fi.height());
                    },
                    error: function (XMLHttpRequest, textStatus, errorThrown) {
                        alert("Our sincerest apologies, but an error occurred while processing the comment response: " + textStatus);
                        fi.find(spinner_selector).fadeOut();
                    },
                    success: function(responseText,statusText) {
                        fi.find(spinner_selector).fadeOut();
                        var comment_html;
                        var comment_id;
                        var comment;
                        if (settings.responseDataType == 'json') {
                            if (typeof responseText.message != 'undefined') {
                                alert(responseText.message);
                                return false;
                            }
                            comment_html = responseText.html;
                            comment      = $(comment_html).hide();
                            comment_id   = responseText.id;
                        } else {
                            if (responseText.match(/comment-error/)) {
                                alert(responseText);
                                return false;
                            }
                            comment_html = responseText;
                            comment      = $(comment_html).hide();
                            comment_id   = comment.attr('id').substr(8);
                        }
                        var parent;
                        if (settings.parentId && settings.wrapClass) {
                            // TODO - make this customizable
                            parent = comment.wrap('<div id="'+settings.wrapClass+'-'+comment_id+
                                                  '" class="'+settings.wrapClass+'"></div>').parent();
                        }
                        if (settings.insertMethod == 'append') {
                            $(settings.target).append(parent ? parent : comment);
                        } else if (settings.insertMethod == 'after') {
                            $(settings.target).after(parent ? parent : comment);
                        }
                        if (settings.onSuccess) { 
                            if (settings.responseDataType == 'text') {
                                settings.onSuccess(form,comment,0);
                            } else if (settings.responseDataType == 'json') {
                                settings.onSuccess(form,comment,0,responseText);
                            }
                        } else { 
                            comment.fadeIn(); 
                        }
                        var r = comment.find(settings.replySelector);
                        if (r) {
                            var opts = $.extend( {}, settings, { 
                                parentId: comment_id, 
                                sourceForm: source,
                                target: comment
                            });
                            r.reply(opts);
                        }
                    }
                };
                $(this).ajaxSubmit(submit_options);
                return false;
            });
        });
        return source;
    };
    $.fn.reply = function(options) {
        var defaults = {
            speed: 'slow',
            sourceForm: $('#comments-form'),
            onReplyClick: null,
            findParentComment: function(e) { return e.closest('.comment'); },
            commentInsertMethod: 'after',
            formInsertMethod: 'after',
            wrapClass: null,
            responseDataType: 'text',
            target: '#comments-list'
        };
        var self;
        var settings = $.extend( {}, defaults, options);
        var clicked = Array();
        var onReplyClick = function() {
            var replyLink = $(this);
            var pid_e = settings.findParentComment( $(this) );
            var pid = pid_e.attr('id').substr(8);
            var pauthor_e = $(this).closest('.byline').find('.vcard.author');
            var pauthor = pauthor_e.html();
            if (!clicked[pid]) {
                // initing the form:
                // 1. clone the source
                var newForm = settings.sourceForm.clone();
                // * making sure the IDs are unique for validity
                var newid = settings.sourceForm.attr('id') + '-' + pid;
                newForm.hide().attr('id',newid);
                if (settings.formInsertMethod == 'append') replyLink.append(newForm);
                if (settings.formInsertMethod == 'after')  replyLink.after(newForm);
                // * running "commentForm on it"
                newForm.commentForm({
                    parentId: pid,
                    loggedInClass: settings.loggedInClass,
                    loggedOutClass: settings.loggedOutClass,
                    insertMethod: settings.commentInsertMethod,
                    wrapClass: settings.wrapClass,
                    responseDataType: settings.responseDataType,
                    target: pid_e,
                    // maybe the comment should be hidden prior to it being shown?
                    onSuccess: function(f,c,pid,response) { 
                        f.slideUp('fast', function() { 
                            c.slideDown(settings.speed, function () {  
                                replyLink.removeClass('expanded').addClass('collapsed');
                            });
                        });
                    }
                });
                clicked[pid] = newForm;
                if (settings.onReplyClick) { 
                    settings.onReplyClick(newForm,pid_e);
                }
                clicked[pid].slideDown(settings.speed, function() {
                    replyLink.addClass('expanded');
                });
            } else if (replyLink.hasClass('expanded')) {
                clicked[pid].slideUp(settings.speed, function() {
                    replyLink.removeClass('expanded').addClass('collapsed');
	            });
            } else if (replyLink.hasClass('collapsed')) {
                clicked[pid].slideDown(settings.speed, function() {
                    replyLink.addClass('expanded').removeClass('collapsed');
	            });
            } else {
                //alert("Fatal error. A form was never initialized for this element.");
            }
        };
        return this.each(function() {
            $(this).click( onReplyClick );
        });
    };
})(jQuery);
