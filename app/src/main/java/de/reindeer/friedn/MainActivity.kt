package de.reindeer.friedn

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.adaptive.navigationsuite.NavigationSuiteScaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.tooling.preview.PreviewScreenSizes
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import de.reindeer.friedn.presentation.view.BlockScreen
import de.reindeer.friedn.presentation.view.LockScreen
import de.reindeer.friedn.presentation.view.TagScreen
import de.reindeer.friedn.ui.theme.FriednTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            FriednTheme {
                FriednApp()
            }
        }
    }
}

@PreviewScreenSizes
@Composable
fun FriednApp() {
    val navController = rememberNavController()
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route

    NavigationSuiteScaffold(
        navigationSuiteItems = {
            AppDestinations.entries.forEach { destination ->
                item(
                    icon = {
                        Icon(
                            destination.icon,
                            contentDescription = destination.label
                        )
                    },
                    label = { Text(destination.label) },
                    selected = destination.name == currentRoute,
                    onClick = { navController.navigate(destination.name) }
                )
            }
        }
    ) {
        NavHost(
            navController = navController,
            startDestination = AppDestinations.LOCK.name
        ) {
            composable(AppDestinations.LOCK.name) { LockScreen() }
            composable(AppDestinations.BLOCK.name) { BlockScreen() }
            composable(AppDestinations.TAG.name) { TagScreen() }
        }
    }
}

enum class AppDestinations(
    val label: String,
    val icon: ImageVector,
) {
    LOCK("Lock", Icons.Default.Lock),
    BLOCK("Block", Icons.Default.Clear),
    TAG("Tag", Icons.Default.Settings),
}