package com.biblestudy.app.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.FormatSize
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.biblestudy.app.ui.theme.InkMuted
import com.biblestudy.app.ui.theme.ScriptureBodyStyle
import com.biblestudy.app.ui.theme.VerseNumberStyle

@Composable
fun ReaderScreen(modifier: Modifier = Modifier) {
    val scroll = rememberScrollState()

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(scroll)
            .padding(horizontal = 20.dp),
    ) {
        Spacer(modifier = Modifier.height(4.dp))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column {
                Text(
                    text = "John 14",
                    style = MaterialTheme.typography.headlineMedium,
                )
                Text(
                    text = "Christian Standard Bible",
                    style = MaterialTheme.typography.bodyMedium,
                    color = InkMuted,
                )
            }
            Row {
                IconButton(onClick = { }) {
                    Icon(Icons.Outlined.FormatSize, contentDescription = "Text size")
                }
                IconButton(onClick = { }) {
                    Icon(Icons.Outlined.Tune, contentDescription = "Reader settings")
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        AssistChip(
            onClick = { },
            label = { Text("Study mode · Off") },
            leadingIcon = {
                Text("◎", style = MaterialTheme.typography.labelLarge)
            },
            colors = AssistChipDefaults.assistChipColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant,
            ),
        )

        Spacer(modifier = Modifier.height(20.dp))

        ScriptureBlock(
            verses = listOf(
                1 to "\"Do not let your heart be troubled. Believe in God; believe also in me.",
                2 to "In my Father's house are many rooms. If it were not so, would I have told you that I am going to prepare a place for you?",
                3 to "If I go away and prepare a place for you, I will come again and take you to myself, so that where I am you may be also.",
                4 to "You know the way to where I am going.\"",
                5 to "\"Lord,\" Thomas said, \"we don't know where you're going. How can we know the way?\"",
                6 to "Jesus told him, \"I am the way, the truth, and the life. No one comes to the Father except through me.",
            ),
        )

        Spacer(modifier = Modifier.height(24.dp))

        Card(
            shape = RoundedCornerShape(18.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer,
            ),
        ) {
            Column(modifier = Modifier.padding(18.dp)) {
                Text(
                    text = "Reflection prompt",
                    style = MaterialTheme.typography.titleMedium,
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Where do you most need Jesus as the way, the truth, and the life this week?",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                )
                Spacer(modifier = Modifier.height(14.dp))
                FilledTonalButton(onClick = { }) {
                    Text("Jot a short note")
                }
            }
        }

        Spacer(modifier = Modifier.height(100.dp))
    }
}

@Composable
private fun ScriptureBlock(verses: List<Pair<Int, String>>) {
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        verses.forEach { (num, text) ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Start,
            ) {
                Box(
                    modifier = Modifier
                        .width(28.dp)
                        .padding(top = 2.dp),
                    contentAlignment = Alignment.TopEnd,
                ) {
                    Text(
                        text = num.toString(),
                        style = VerseNumberStyle,
                        color = InkMuted,
                    )
                }
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = text,
                    style = ScriptureBodyStyle,
                    color = MaterialTheme.colorScheme.onBackground,
                )
            }
        }
    }
}
