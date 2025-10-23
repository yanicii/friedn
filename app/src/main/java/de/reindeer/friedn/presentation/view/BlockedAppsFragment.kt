package de.reindeer.friedn.presentation.view

import android.content.Intent
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.selection.toggleable
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.intl.Locale
import androidx.compose.ui.text.toLowerCase
import androidx.compose.ui.unit.dp
import com.google.accompanist.drawablepainter.rememberDrawablePainter
import de.reindeer.friedn.data.BlockedAppsRepository
import de.reindeer.friedn.domain.AppInfo
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

@Composable
fun BlockScreen() {
    val context = LocalContext.current
    val packageManager = context.packageManager
    val repository = remember { BlockedAppsRepository(context) }
    var apps by remember { mutableStateOf<List<AppInfo>?>(null) }

    LaunchedEffect(Unit) {
        withContext(Dispatchers.IO) {
            val mainIntent = Intent(Intent.ACTION_MAIN, null)
            mainIntent.addCategory(Intent.CATEGORY_LAUNCHER)
            val lockedApps = repository.getLockedApps()
            apps = packageManager.queryIntentActivities(mainIntent, 0)
                .map { 
                    AppInfo(
                        it.loadLabel(packageManager).toString(), 
                        it.activityInfo.packageName,
                        it.loadIcon(packageManager),
                        lockedApps.contains(it.activityInfo.packageName)
                    )
                }
                .sortedBy { it.name.toLowerCase(Locale.current) }
        }
    }

    if (apps == null) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator()
        }
    } else {
        LazyColumn {
            items(apps!!) { app ->
                AppListItem(app = app, repository = repository)
            }
        }
    }
}

@Composable
fun AppListItem(app: AppInfo, repository: BlockedAppsRepository) {
    val isChecked = remember { mutableStateOf(app.isSelected) }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(8.dp, 24.dp, 8.dp, 0.dp)
            .toggleable(
                value = isChecked.value,
                onValueChange = {
                    isChecked.value = it
                    app.isSelected = it
                    if (it) {
                        repository.addLockedApp(app.packageName)
                    } else {
                        repository.removeLockedApp(app.packageName)
                    }
                },
                role = Role.Checkbox
            ),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Image(
            painter = rememberDrawablePainter(drawable = app.icon),
            contentDescription = app.name,
            modifier = Modifier.size(40.dp)
        )
        Text(
            text = app.name,
            modifier = Modifier.weight(1f).padding(start = 8.dp)
        )
        Checkbox(
            checked = isChecked.value,
            onCheckedChange = null
        )
    }
}