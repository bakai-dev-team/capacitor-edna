package kg.bakai.capacitor.edna

import android.content.Context
import edna.chatcenter.ui.visual.uiStyle.settings.structures.SideSize
import android.graphics.Typeface
import edna.chatcenter.ui.visual.uiStyle.settings.theme.ChatTypography
import edna.chatcenter.ui.visual.uiStyle.settings.styles.ChatFontStyle
import edna.chatcenter.ui.visual.uiStyle.settings.ChatTheme
import edna.chatcenter.ui.visual.uiStyle.settings.components.ChatComponents
import edna.chatcenter.ui.visual.uiStyle.settings.flows.ChatFlows
import edna.chatcenter.ui.visual.uiStyle.settings.theme.ChatImages
import edna.chatcenter.ui.visual.uiStyle.settings.theme.ChatColors

/** Mirrors mobile-banking/src/theme/variables.scss, including the IFC palette. */
internal object BakaiEdnaTheme {
    fun create(context: Context, name: String): ChatTheme {
        val regularPath = "public/assets/fonts/sfpro/SFProDisplay-Regular.ttf"
        val semiboldPath = "public/assets/fonts/sfpro/SFProDisplay-Semibold.ttf"
        val bankRegular = runCatching { Typeface.createFromAsset(context.assets, regularPath) }.getOrDefault(Typeface.DEFAULT)
        val bankSemibold = runCatching { Typeface.createFromAsset(context.assets, semiboldPath) }.getOrDefault(Typeface.DEFAULT_BOLD)
        val typography = ChatTypography().apply {
            regular.fontPath = bankRegular
            medium.fontPath = bankRegular
            mediumUpper.fontPath = bankRegular
            small.fontPath = bankRegular
            big.fontPath = bankRegular
            error.fontPath = bankRegular

            if (runCatching { context.assets.open(regularPath).close() }.isSuccess) {
                defaultFontRegularPath = regularPath
                defaultFontLightPath = regularPath

                // Даже там, где SDK просит Bold, даём Regular
                defaultFontBoldPath = regularPath

                bubbleMessageFontPath = regularPath
                bubbleTimeFontPath = regularPath

                toolbarTitleFontPath = regularPath
                toolbarSubtitleFontPath = regularPath

                inputQuotedMessageFontPath = regularPath
                quoteMessageFontPath = regularPath
                quoteTimeFontPath = regularPath

                quoteAuthorFontPath = regularPath
                quoteHeaderFontPath = regularPath
            }
        }
        val colors = ChatColors()
        when (name) {
            "light" -> colors.apply {
                main = R.color.bakai_edna_light_accent
                backButton = R.color.bakai_edna_light_accent
                bodyIconsTint = R.color.bakai_edna_light_accent
                toolbar = R.color.bakai_edna_light_background
                statusBar = R.color.bakai_edna_light_background
                toolbarText = R.color.bakai_edna_light_text
                incomingText = R.color.bakai_edna_light_text
                outgoingText = R.color.bakai_edna_light_text
                incomingLink = R.color.bakai_edna_light_accent
                outgoingLink = R.color.bakai_edna_light_accent
                incomingBubble = R.color.bakai_edna_light_incoming
                outgoingBubble = R.color.bakai_edna_light_outgoing
                systemMessage = R.color.bakai_edna_light_muted
                incomingTimeText = R.color.bakai_edna_light_muted
                outgoingTimeText = R.color.bakai_edna_light_muted
                inputMessage = R.color.bakai_edna_light_text
                inputMessageHint = R.color.bakai_edna_light_muted
                inputFieldBackground = R.color.bakai_edna_light_input
                chatBackground = R.color.bakai_edna_light_background
                sendBtnIconColor = R.color.bakai_edna_light_accent
                voiceBtnIconColor = R.color.bakai_edna_light_accent
                messageReadStatus = R.color.bakai_edna_read
                quoteText = R.color.bakai_edna_light_text
                quoteColorText = R.color.bakai_edna_light_text
                quoteBgColor = R.color.bakai_edna_light_input
                quoteAuthorColorText = R.color.bakai_edna_light_accent
                quoteDelimiterColor = R.color.bakai_edna_light_accent
                mediaAndFilesText = R.color.bakai_edna_light_text
                searchText = R.color.bakai_edna_light_text
                searchHint = R.color.bakai_edna_light_muted
                searchResultBackground = R.color.bakai_edna_light_background
                toolbarContextMenu = R.color.bakai_edna_light_incoming
                menuItem = R.color.bakai_edna_light_text
                popupsBackground = R.color.bakai_edna_light_incoming
                emptyStateBackground = R.color.bakai_edna_light_background
                welcomeScreenTitleText = R.color.bakai_edna_light_text
                welcomeScreenSubtitleText = R.color.bakai_edna_light_muted
                quickRepliesText = R.color.bakai_edna_light_accent
                quickReplyButtonBackgroundTint = R.color.bakai_edna_light_input
            }
            "ifcLight" -> colors.apply {
                main = R.color.bakai_edna_ifclight_accent
                backButton = R.color.bakai_edna_ifclight_accent
                bodyIconsTint = R.color.bakai_edna_ifclight_accent
                toolbar = R.color.bakai_edna_ifclight_background
                statusBar = R.color.bakai_edna_ifclight_background
                toolbarText = R.color.bakai_edna_ifclight_text
                incomingText = R.color.bakai_edna_ifclight_text
                outgoingText = R.color.bakai_edna_ifclight_text
                incomingLink = R.color.bakai_edna_ifclight_accent
                outgoingLink = R.color.bakai_edna_ifclight_accent
                incomingBubble = R.color.bakai_edna_ifclight_incoming
                outgoingBubble = R.color.bakai_edna_ifclight_outgoing
                systemMessage = R.color.bakai_edna_ifclight_muted
                incomingTimeText = R.color.bakai_edna_ifclight_muted
                outgoingTimeText = R.color.bakai_edna_ifclight_muted
                inputMessage = R.color.bakai_edna_ifclight_text
                inputMessageHint = R.color.bakai_edna_ifclight_muted
                inputFieldBackground = R.color.bakai_edna_ifclight_input
                chatBackground = R.color.bakai_edna_ifclight_background
                sendBtnIconColor = R.color.bakai_edna_ifclight_accent
                voiceBtnIconColor = R.color.bakai_edna_ifclight_accent
                messageReadStatus = R.color.bakai_edna_ifc_read
                quoteText = R.color.bakai_edna_ifclight_text
                quoteColorText = R.color.bakai_edna_ifclight_text
                quoteBgColor = R.color.bakai_edna_ifclight_input
                quoteAuthorColorText = R.color.bakai_edna_ifclight_accent
                quoteDelimiterColor = R.color.bakai_edna_ifclight_accent
                mediaAndFilesText = R.color.bakai_edna_ifclight_text
                searchText = R.color.bakai_edna_ifclight_text
                searchHint = R.color.bakai_edna_ifclight_muted
                searchResultBackground = R.color.bakai_edna_ifclight_background
                toolbarContextMenu = R.color.bakai_edna_ifclight_incoming
                menuItem = R.color.bakai_edna_ifclight_text
                popupsBackground = R.color.bakai_edna_ifclight_incoming
                emptyStateBackground = R.color.bakai_edna_ifclight_background
                welcomeScreenTitleText = R.color.bakai_edna_ifclight_text
                welcomeScreenSubtitleText = R.color.bakai_edna_ifclight_muted
                quickRepliesText = R.color.bakai_edna_ifclight_accent
                quickReplyButtonBackgroundTint = R.color.bakai_edna_ifclight_input
            }
            "dark" -> colors.apply {
                main = R.color.bakai_edna_dark_accent
                backButton = R.color.bakai_edna_dark_accent
                bodyIconsTint = R.color.bakai_edna_dark_accent
                toolbar = R.color.bakai_edna_dark_background
                statusBar = R.color.bakai_edna_dark_background
                toolbarText = R.color.bakai_edna_dark_text
                incomingText = R.color.bakai_edna_dark_text
                outgoingText = R.color.bakai_edna_dark_text
                incomingLink = R.color.bakai_edna_dark_accent
                outgoingLink = R.color.bakai_edna_dark_accent
                incomingBubble = R.color.bakai_edna_dark_incoming
                outgoingBubble = R.color.bakai_edna_dark_outgoing
                systemMessage = R.color.bakai_edna_dark_muted
                incomingTimeText = R.color.bakai_edna_dark_muted
                outgoingTimeText = R.color.bakai_edna_dark_muted
                inputMessage = R.color.bakai_edna_dark_text
                inputMessageHint = R.color.bakai_edna_dark_muted
                inputFieldBackground = R.color.bakai_edna_dark_input
                chatBackground = R.color.bakai_edna_dark_background
                sendBtnIconColor = R.color.bakai_edna_dark_accent
                voiceBtnIconColor = R.color.bakai_edna_dark_accent
                messageReadStatus = R.color.bakai_edna_read
                quoteText = R.color.bakai_edna_dark_text
                quoteColorText = R.color.bakai_edna_dark_text
                quoteBgColor = R.color.bakai_edna_dark_input
                quoteAuthorColorText = R.color.bakai_edna_dark_accent
                quoteDelimiterColor = R.color.bakai_edna_dark_accent
                mediaAndFilesText = R.color.bakai_edna_dark_text
                searchText = R.color.bakai_edna_dark_text
                searchHint = R.color.bakai_edna_dark_muted
                searchResultBackground = R.color.bakai_edna_dark_background
                toolbarContextMenu = R.color.bakai_edna_dark_incoming
                menuItem = R.color.bakai_edna_dark_text
                popupsBackground = R.color.bakai_edna_dark_incoming
                emptyStateBackground = R.color.bakai_edna_dark_background
                welcomeScreenTitleText = R.color.bakai_edna_dark_text
                welcomeScreenSubtitleText = R.color.bakai_edna_dark_muted
                quickRepliesText = R.color.bakai_edna_dark_accent
                quickReplyButtonBackgroundTint = R.color.bakai_edna_dark_input
            }
            "ifcDark" -> colors.apply {
                main = R.color.bakai_edna_ifcdark_accent
                backButton = R.color.bakai_edna_ifcdark_accent
                bodyIconsTint = R.color.bakai_edna_ifcdark_accent
                toolbar = R.color.bakai_edna_ifcdark_background
                statusBar = R.color.bakai_edna_ifcdark_background
                toolbarText = R.color.bakai_edna_ifcdark_text
                incomingText = R.color.bakai_edna_ifcdark_text
                outgoingText = R.color.bakai_edna_ifcdark_text
                incomingLink = R.color.bakai_edna_ifcdark_accent
                outgoingLink = R.color.bakai_edna_ifcdark_accent
                incomingBubble = R.color.bakai_edna_ifcdark_incoming
                outgoingBubble = R.color.bakai_edna_ifcdark_outgoing
                systemMessage = R.color.bakai_edna_ifcdark_muted
                incomingTimeText = R.color.bakai_edna_ifcdark_muted
                outgoingTimeText = R.color.bakai_edna_ifcdark_muted
                inputMessage = R.color.bakai_edna_ifcdark_text
                inputMessageHint = R.color.bakai_edna_ifcdark_muted
                inputFieldBackground = R.color.bakai_edna_ifcdark_input
                chatBackground = R.color.bakai_edna_ifcdark_background
                sendBtnIconColor = R.color.bakai_edna_ifcdark_accent
                voiceBtnIconColor = R.color.bakai_edna_ifcdark_accent
                messageReadStatus = R.color.bakai_edna_ifc_read
                quoteText = R.color.bakai_edna_ifcdark_text
                quoteColorText = R.color.bakai_edna_ifcdark_text
                quoteBgColor = R.color.bakai_edna_ifcdark_input
                quoteAuthorColorText = R.color.bakai_edna_ifcdark_accent
                quoteDelimiterColor = R.color.bakai_edna_ifcdark_accent
                mediaAndFilesText = R.color.bakai_edna_ifcdark_text
                searchText = R.color.bakai_edna_ifcdark_text
                searchHint = R.color.bakai_edna_ifcdark_muted
                searchResultBackground = R.color.bakai_edna_ifcdark_background
                toolbarContextMenu = R.color.bakai_edna_ifcdark_incoming
                menuItem = R.color.bakai_edna_ifcdark_text
                popupsBackground = R.color.bakai_edna_ifcdark_incoming
                emptyStateBackground = R.color.bakai_edna_ifcdark_background
                welcomeScreenTitleText = R.color.bakai_edna_ifcdark_text
                welcomeScreenSubtitleText = R.color.bakai_edna_ifcdark_muted
                quickRepliesText = R.color.bakai_edna_ifcdark_accent
                quickReplyButtonBackgroundTint = R.color.bakai_edna_ifcdark_input
            }
            else -> return create(context, "light")
        }
        // These controls have independent defaults in the SDK. Setting the base
        // palette alone leaves a white composer and low-contrast search/reply UI.
        colors.loaderTextColor = colors.incomingText
        colors.messageHighlighting = R.color.bakai_edna_selection
        colors.searchIcon = colors.main
        colors.chatToolbarInverseIconTint = colors.main
        colors.searchBarText = colors.incomingText
        colors.searchResultsItemNameText = colors.incomingText
        colors.searchResultsItemMessageText = colors.incomingText
        colors.searchResultsItemDateText = colors.inputMessageHint
        colors.searchResultsItemRightArrowTint = colors.inputMessageHint
        colors.searchResultsDivider = colors.inputMessageHint
        colors.searchResultNoItemsText = colors.inputMessageHint
        colors.searchHighlight = colors.main
        colors.chatToolbarHintText = colors.inputMessageHint
        colors.quoteHeaderChatView = colors.incomingText
        colors.quoteClearIcon = colors.main
        val statusTint = when (name) {
            "dark" -> R.color.bakai_edna_dark_muted
            "ifcDark" -> R.color.bakai_edna_ifcdark_status
            else -> R.color.bakai_edna_light_status
        }
        colors.messageSendingStatus = statusTint
        colors.messageSentStatus = statusTint
        colors.messageDeliveredStatus = statusTint
        colors.chatErrorScreenMessageText = colors.incomingText
        colors.chatErrorScreenButtonText = colors.main
        colors.chatErrorScreenImageTint = colors.inputMessageHint
        val images = ChatImages().apply {
            logoImage = R.drawable.bakai_edna_welcome
            messageSending = R.drawable.bakai_edna_sending
            searchResultNoItemsImage = R.drawable.bakai_edna_search_empty
            operatorAvatarPlaceholder = R.drawable.bakai_edna_operator_avatar
        }
        // Android small notification icons use a white silhouette on transparency.
        images.pushIcon = R.drawable.bakai_edna_notification
        // COLOR_DEFAULT removes the SDK's green accent; Android owns final rendering.
        colors.pushBackground = android.R.color.transparent
        val components = ChatComponents(context, colors = colors, images = images, typography = typography)
        components.searchChatComponent.textInput.apply {
            this?.textColor = colors?.incomingText
            this?.hintColor = colors?.inputMessageHint
        }
        val flows = ChatFlows(components)
        flows.chatFlow.apply {
            for (messages in listOf(incomeMessages, outcomeMessages, errorMessages)) {
                messages.chatBubble.margins = (messages.chatBubble.margins ?: SideSize()).copy(
                    left = R.dimen.bakai_edna_metadata_gap,
                    right = R.dimen.bakai_edna_metadata_gap
                )
                messages.chatBubble.imageResId = R.drawable.bakai_edna_message_bubble
                messages.chatBubble.paddings = SideSize(
                    left = R.dimen.bakai_edna_bubble_horizontal, right = R.dimen.bakai_edna_bubble_horizontal,
                    top = R.dimen.bakai_edna_bubble_vertical, bottom = R.dimen.bakai_edna_bubble_vertical
                )
                messages.mainText.font = ChatFontStyle(bankRegular, R.dimen.bakai_edna_message_text_size)
                messages.mainText.text?.isBold = false
                messages.timeText.font = ChatFontStyle(bankRegular, R.dimen.bakai_edna_time_text_size)
                messages.timeText.text?.isBold = false
            }
            for (text in listOf(systemMessages.requestToResolve, systemMessages.approveRequest, systemMessages.denyRequest)) {
                text.font = ChatFontStyle(bankRegular, R.dimen.bakai_edna_message_text_size)
                text.text?.isBold = false
                text.textColor = if (text === systemMessages.requestToResolve) colors.incomingText else colors.main
            }
            dateText.font = ChatFontStyle(bankRegular, R.dimen.bakai_edna_date_text_size)
            navigationBar.copyButton.style.iconTintColor = colors.inputMessageHint
            navigationBar.replyButton.style.iconTintColor = colors.inputMessageHint
            navigationBar.apply {
                visibleShadow = true
                backgroundColor = android.R.color.transparent
                toolbarHeaderText.font = ChatFontStyle(bankSemibold, R.dimen.bakai_edna_title_text_size)
                toolbarSubtitleText.font = ChatFontStyle(bankRegular, R.dimen.bakai_edna_subtitle_text_size)
                for (button in listOf(backButton, searchButton)) {
                    button.style.backgroundColor = null
                    button.style.background = R.drawable.bakai_edna_round_button
                    button.style.iconTintColor = colors.incomingText
                }
            }
            inputView.sendButton.iconRes = R.drawable.bakai_edna_send
            inputView.sendButton.style.backgroundColor = null
            inputView.sendButton.style.background = R.drawable.bakai_edna_round_button
            inputView.attachButton.iconRes = R.drawable.bakai_edna_attach
            inputView.attachButton.style.iconTintColor = colors.inputMessageHint
            inputView.nearbyAreaBackgroundColor = null
            inputView.textInput.apply {
                this?.textColor = colors.inputMessage
                this?.hintColor = colors.inputMessageHint
                this?.background?.backgroundColor = android.R.color.transparent
                this?.background?.backgroundDrawableRes = null
                this?.inputSizes = null
                this?.marginSizes = null
                this?.placeholderTextResId = R.string.bakai_edna_input_placeholder
                this?.font = ChatFontStyle(bankRegular, R.dimen.bakai_edna_input_text_size)
            }
            quoteView.apply {
                quoteHeaderChatViewText.textColor = colors.incomingText
                quoteMessageChatViewText.textColor = colors.incomingText
                quoteDurationChatViewText.textColor = colors.inputMessageHint
                quoteClearIconButton.style.iconTintColor = colors.main
                quoteIcon.style.iconTintColor = colors.main
            }
        }
        flows.chatFlow.retryChatInitButton.apply {
            buttonColor = colors.inputFieldBackground
            colorStateList = android.content.res.ColorStateList.valueOf(
                androidx.core.content.ContextCompat.getColor(context, colors.inputFieldBackground))
            chatText?.apply {
                textColor = colors.incomingText
                font = ChatFontStyle(bankRegular, R.dimen.bakai_edna_message_text_size)
                text?.isBold = false
            }
        }
        flows.galleryFlow.apply {
            // SDK flows share components: copy mutable styles before changing media UI.
            screenAuthor = screenAuthor.copy(
                textColor = android.R.color.white,
                font = ChatFontStyle(bankSemibold, R.dimen.bakai_edna_title_text_size))
            screenDate = screenDate.copy(
                textColor = R.color.bakai_edna_media_caption,
                font = ChatFontStyle(bankRegular, R.dimen.bakai_edna_subtitle_text_size))
            imageScreenBackgroundColor = colors.searchResultBackground
            val circle = when (name) {
                "dark" -> R.drawable.bakai_edna_media_button_dark
                "ifcDark" -> R.drawable.bakai_edna_media_button_ifcdark
                else -> R.drawable.bakai_edna_media_button_light
            }
            val original = navigationBarStyle
            fun mediaButton(button: edna.chatcenter.ui.visual.uiStyle.settings.components.iconButton.IconButtonChatStyle) =
                button.copy(style = button.style.copy(background = circle,
                    backgroundColor = null, iconTintColor = colors.incomingText, colorStateList = null))
            navigationBarStyle = original.copy(
                backgroundColor = colors.searchResultBackground,
                toolbarHeaderText = original.toolbarHeaderText.copy(
                    textColor = colors.incomingText,
                    font = ChatFontStyle(bankSemibold, R.dimen.bakai_edna_title_text_size)),
                backButton = mediaButton(original.backButton).copy(iconRes = R.drawable.bakai_edna_media_back),
                invertedBackButton = mediaButton(original.invertedBackButton).copy(iconRes = R.drawable.bakai_edna_media_back),
                menuButton = mediaButton(original.menuButton))
        }
        flows.chatFlow.welcomeScreenStyle.welcomeScreenImage.apply {
            imageResId = R.drawable.bakai_edna_welcome
            tintColor = null
        }
        flows.bottomMenuChatFlow.apply {
            val dark = name == "dark" || name == "ifcDark"
            backgroundColor = if (dark) R.color.bakai_edna_menu_dark_surface else R.color.bakai_edna_menu_light_surface
            for ((button, icon) in listOf(
                galleryButton to R.drawable.bakai_edna_attachment_gallery_vector,
                cameraButton to R.drawable.bakai_edna_attachment_camera_vector,
                fileButton to R.drawable.bakai_edna_attachment_document_vector)) {
                button?.backgroundColor = if (dark) R.color.bakai_edna_menu_dark_button else R.color.bakai_edna_menu_light_button
                button?.textColor = if (dark) R.color.bakai_edna_menu_dark_text else R.color.bakai_edna_menu_light_text
                button?.tintColor = if (dark) R.color.bakai_edna_menu_dark_icon else R.color.bakai_edna_menu_light_icon
                button?.textSize = R.dimen.bakai_edna_message_text_size
                button?.icon = icon
            }
        }
        return ChatTheme(flows)
    }
}
