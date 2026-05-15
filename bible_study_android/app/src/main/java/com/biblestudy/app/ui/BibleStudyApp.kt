package com.biblestudy.app.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoStories
import androidx.compose.material.icons.filled.EditNote
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.MenuBook
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.biblestudy.app.ui.screens.HomeScreen
import com.biblestudy.app.ui.screens.JournalScreen
import com.biblestudy.app.ui.screens.PlansScreen
import com.biblestudy.app.ui.screens.ReaderScreen
import com.biblestudy.app.ui.theme.BibleStudyTheme

private sealed class MainDestination(
    val route: String,
    val label: String,
    val icon: ImageVector,
) {
    data object Home : MainDestination("home", "Home", Icons.Filled.Home)
    data object Read : MainDestination("read", "Read", Icons.Filled.MenuBook)
    data object Plans : MainDestination("plans", "Plans", Icons.Filled.AutoStories)
    data object Journal : MainDestination("journal", "Journal", Icons.Filled.EditNote)
}

private val mainDestinations = listOf(
    MainDestination.Home,
    MainDestination.Read,
    MainDestination.Plans,
    MainDestination.Journal,
)

@Composable
fun BibleStudyApp() {
    BibleStudyTheme(dynamicColor = false) {
        val navController = rememberNavController()
        val backStackEntry by navController.currentBackStackEntryAsState()
        val current = backStackEntry?.destination

        Scaffold(
            bottomBar = {
                NavigationBar {
                    mainDestinations.forEach { dest ->
                        val selected = current?.hierarchy?.any { it.route == dest.route } == true
                        NavigationBarItem(
                            selected = selected,
                            onClick = {
                                navController.navigate(dest.route) {
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            icon = { Icon(dest.icon, contentDescription = dest.label) },
                            label = { Text(dest.label) },
                            colors = NavigationBarItemDefaults.colors(),
                        )
                    }
                }
            },
        ) { innerPadding ->
            NavHost(
                navController = navController,
                startDestination = MainDestination.Home.route,
                modifier = Modifier.padding(innerPadding),
            ) {
                composable(MainDestination.Home.route) { HomeScreen() }
                composable(MainDestination.Read.route) { ReaderScreen() }
                composable(MainDestination.Plans.route) { PlansScreen() }
                composable(MainDestination.Journal.route) { JournalScreen() }
            }
        }
    }
}
