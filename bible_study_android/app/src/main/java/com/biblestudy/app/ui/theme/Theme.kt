package com.biblestudy.app.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext

private val LightColors = lightColorScheme(
    primary = Forest,
    onPrimary = Parchment,
    primaryContainer = ForestSoft,
    onPrimaryContainer = Ink,
    secondary = AccentGold,
    onSecondary = Ink,
    secondaryContainer = AccentGoldSoft,
    onSecondaryContainer = Ink,
    tertiary = InkMuted,
    background = Parchment,
    onBackground = Ink,
    surface = Parchment,
    onSurface = Ink,
    surfaceVariant = ParchmentDeep,
    onSurfaceVariant = InkMuted,
    outline = CardStroke,
)

private val DarkColors = darkColorScheme(
    primary = ForestSoft,
    onPrimary = Ink,
    primaryContainer = Forest,
    onPrimaryContainer = Parchment,
    secondary = AccentGold,
    onSecondary = Ink,
    secondaryContainer = InkMuted,
    onSecondaryContainer = Parchment,
    background = Ink,
    onBackground = Parchment,
    surface = Ink,
    onSurface = Parchment,
    surfaceVariant = InkMuted,
    onSurfaceVariant = ParchmentDeep,
)

@Composable
fun BibleStudyTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit,
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColors
        else -> LightColors
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = BibleStudyTypography,
        content = content,
    )
}
