# Network Tree UI Component

## Overview
Network Tree UI แสดงโครงสร้าง referral network แบบ hierarchical tree ที่มี 5 slots per parent (ACF 5×7 structure)

## HTML Structure

### Tab Headers
```html
<div class="flex border-b border-gray-700">
    <button onclick="switchNetworkTab('table')"
            id="tabTableView"
            class="px-6 py-3 text-white bg-gray-700 border-b-2 border-emerald-500 transition-colors">
        <i class="fas fa-table mr-2"></i>
        DNA Database
    </button>
    <button onclick="switchNetworkTab('tree')"
            id="tabTreeView"
            class="px-6 py-3 text-gray-400 hover:text-white hover:bg-gray-700 transition-colors">
        <i class="fas fa-sitemap mr-2"></i>
        Network Tree
    </button>
</div>
```

### Tree Container
```html
<div id="networkTreeTab" class="p-6" style="display: none;">
    <!-- Tree Header -->
    <div class="flex items-center justify-between mb-4">
        <div class="flex items-center gap-3">
            <div id="treeRootAvatar" class="w-10 h-10 rounded-full bg-gray-700 flex items-center justify-center ring-2 ring-emerald-500">
                <i class="fas fa-user text-gray-400"></i>
            </div>
            <div>
                <div id="treeRootInfo" class="text-sm font-semibold text-white">Network Tree</div>
                <div class="text-xs text-gray-400">Horizontal View</div>
            </div>
        </div>
        <div class="flex items-center gap-2">
            <label class="text-sm text-gray-300">View from:</label>
            <select id="treeRootSelector" onchange="changeTreeRoot()"
                    class="bg-gray-700 text-white px-3 py-1.5 rounded-lg border border-gray-600 text-sm">
                <option value="">Select user...</option>
            </select>
        </div>
    </div>

    <p class="text-xs text-gray-400 mb-4">
        Showing network structure with profile pictures • Click on any profile to view their subtree
    </p>

    <!-- Tree Content (Dynamic) -->
    <div id="networkTreeContainer" class="space-y-6">
        <div class="text-center py-8 text-gray-400">
            <i class="fas fa-spinner fa-spin text-2xl mb-2"></i>
            <p>Loading network tree...</p>
        </div>
    </div>
</div>
```

## CSS Styles

```css
<style>
    .network-rows {
        display: grid;
        grid-auto-rows: 1fr;
        row-gap: 16px;
    }
    .network-rows .row {
        display: grid;
        grid-template-columns: 280px 1fr;
        column-gap: 16px;
        align-items: stretch;
    }
    .parent-card, .children-wrap {
        height: 100%;
    }
    .parent-card {
        display: flex;
        flex-direction: column;
        padding: 12px;
        border-radius: 8px;
        background: rgba(31, 41, 55, 0.5);
        border: 1px solid rgb(55, 65, 81);
        transition: all 0.2s;
        cursor: pointer;
    }
    .parent-card:hover {
        background: rgb(31, 41, 55);
        border-color: rgb(16, 185, 129);
    }
    .children-wrap {
        display: grid;
        grid-template-columns: repeat(5, minmax(120px, 1fr));
        gap: 12px;
        align-content: start;
        padding: 8px;
        border-left: 2px solid rgb(55, 65, 81);
    }
    .child-card {
        display: flex;
        flex-direction: column;
        align-items: center;
        padding: 8px;
        border-radius: 8px;
        background: rgba(31, 41, 55, 0.3);
        border: 1px solid rgb(55, 65, 81);
        transition: all 0.2s;
        cursor: pointer;
        min-height: 120px;
    }
    .child-card:hover {
        background: rgb(31, 41, 55);
        border-color: rgb(6, 182, 212);
    }
    .child-card.empty {
        border: 2px dashed rgb(55, 65, 81);
        cursor: default;
        background: transparent;
    }
    .child-card.empty:hover {
        background: transparent;
        border-color: rgb(55, 65, 81);
    }
</style>
```

## JavaScript Functions

### Main Render Function
```javascript
function renderNetworkTree(data, root) {
    const container = document.getElementById('networkTreeContainer');
    const rootAvatar = document.getElementById('treeRootAvatar');
    const rootInfo = document.getElementById('treeRootInfo');

    // Update root info
    if (rootInfo) {
        rootInfo.innerHTML = `${root.user_id} <span class="text-gray-400">· ${root.username || 'Unknown'} · <span class="text-emerald-400">${root.child_count || 0} children</span></span>`;
    }

    // Update root avatar
    if (rootAvatar) {
        const avatarUrl = getAvatarUrl(root);
        if (avatarUrl) {
            rootAvatar.innerHTML = `<img src="${avatarUrl}" class="w-full h-full object-cover rounded-full" />`;
        } else {
            rootAvatar.innerHTML = `<i class="fas fa-user text-gray-400"></i>`;
        }
    }

    // Build parent-child map
    const childrenMap = {};
    data.forEach(node => {
        if (node.parent_id) {
            if (!childrenMap[node.parent_id]) {
                childrenMap[node.parent_id] = [];
            }
            childrenMap[node.parent_id].push(node);
        }
    });

    // Sort children by registration time (earliest first)
    Object.keys(childrenMap).forEach(parentId => {
        childrenMap[parentId].sort((a, b) => {
            return new Date(a.regist_time) - new Date(b.regist_time);
        });
    });

    // Get direct children of root (first column - max 5)
    const directChildren = (childrenMap[root.user_id] || []).slice(0, 5);

    // Render tree with grid structure
    container.innerHTML = `
        ${navigationHistory.length > 0 ? `
            <div class="mb-4">
                <button onclick="navigateBack()"
                        class="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition-colors inline-flex items-center gap-2">
                    <i class="fas fa-arrow-left"></i>
                    Back to Previous Level
                    <span class="text-xs text-gray-400 ml-2">(${navigationHistory.length} level${navigationHistory.length > 1 ? 's' : ''} back)</span>
                </button>
            </div>
        ` : ''}

        <section class="network-rows">
            ${directChildren.length > 0 ? directChildren.map((parent, idx) => {
                const grandChildren = (childrenMap[parent.user_id] || []).slice(0, 5);
                const parentChildCount = parent.child_count || 0;
                const emptySlots = Math.max(0, 5 - grandChildren.length);

                return `
                    <div class="row">
                        <!-- Parent Card -->
                        <article class="parent-card" onclick="loadNetworkTree('${parent.user_id}')">
                            <div class="flex items-center gap-3 mb-2">
                                ${renderAvatarWithBadge(parent, 'ring-emerald-400', parentChildCount)}
                                <div class="flex-1 min-w-0">
                                    <div class="text-sm font-semibold text-white truncate">${parent.username || parent.user_id}</div>
                                    <div class="text-[10px] text-gray-400">${parent.user_id}</div>
                                </div>
                            </div>
                            <div class="text-[10px] text-emerald-400 mt-auto">
                                <i class="fas fa-sitemap mr-1"></i>${parentChildCount} children
                            </div>
                        </article>

                        <!-- Children Wrap -->
                        <div class="children-wrap">
                            <div class="col-span-5 text-xs font-semibold text-gray-400 mb-2">
                                <i class="fas fa-arrow-right mr-2"></i>
                                Children of <span class="text-white">${parent.username || parent.user_id}</span>
                                <span class="text-gray-500 ml-2">(${grandChildren.length}/5)</span>
                            </div>
                            ${grandChildren.map(child => {
                                const childCount = child.child_count || 0;
                                return `
                                    <div class="child-card" onclick="loadNetworkTree('${child.user_id}')">
                                        ${renderAvatarWithBadge(child, 'ring-cyan-400', childCount)}
                                        <div class="text-[10px] mt-2 text-center truncate w-full text-gray-300">
                                            ${child.username || child.user_id}
                                        </div>
                                        <div class="text-[9px] text-cyan-400 mt-1">
                                            <i class="fas fa-sitemap"></i> ${childCount}
                                        </div>
                                    </div>
                                `;
                            }).join('')}
                            ${Array.from({ length: emptySlots }).map((_, i) => `
                                <div class="child-card empty">
                                    <div class="w-10 h-10 rounded-full border-2 border-dashed border-gray-600"></div>
                                    <div class="text-[9px] mt-2 text-gray-600">Slot ${grandChildren.length + i + 1}</div>
                                </div>
                            `).join('')}
                        </div>
                    </div>
                `;
            }).join('') : `
                <div class="text-center py-12 text-gray-500 col-span-2">
                    <i class="fas fa-users-slash text-4xl mb-3"></i>
                    <p>No children yet</p>
                </div>
            `}
        </section>
    `;
}
```

### Helper Functions

```javascript
// Render avatar with child count badge
function renderAvatarWithBadge(user, ringClass = 'ring-gray-500', childCount = 0) {
    const avatarUrl = getAvatarUrl(user);
    const avatarClass = `w-10 h-10 rounded-full overflow-hidden ring-2 ${ringClass} bg-gray-700 flex items-center justify-center`;

    const avatarHtml = avatarUrl
        ? `<img src="${avatarUrl}" alt="${user.username}" class="w-full h-full object-cover" />`
        : `<span class="text-[10px] text-gray-400">N/A</span>`;

    return `
        <div class="relative">
            <div class="${avatarClass}">${avatarHtml}</div>
            ${childCount > 0 ? `
                <div class="absolute -bottom-1 -right-1 bg-emerald-500 text-white text-[9px] font-bold rounded-full w-5 h-5 flex items-center justify-center border-2 border-gray-900">
                    ${childCount}
                </div>
            ` : ''}
        </div>
    `;
}

// Get avatar URL
function getAvatarUrl(user) {
    if (user.profile_image_filename) {
        return `/uploads/profiles/${user.profile_image_filename}`;
    } else if (user.avatar_url) {
        return user.avatar_url;
    } else {
        // Fallback to pravatar
        return `https://i.pravatar.cc/120?u=${user.user_id}`;
    }
}

// Change tree root
function changeTreeRoot() {
    const selector = document.getElementById('treeRootSelector');
    const userId = selector.value;
    if (userId) {
        loadNetworkTree(userId);
    }
}

// Navigate back in tree history
function navigateBack() {
    if (navigationHistory.length > 0) {
        const previousUserId = navigationHistory.pop();
        loadNetworkTree(previousUserId, false); // false = don't add to history
    }
}

// Load network tree for specific user
function loadNetworkTree(userId, addToHistory = true) {
    if (addToHistory && currentTreeRoot && currentTreeRoot !== userId) {
        navigationHistory.push(currentTreeRoot);
    }
    currentTreeRoot = userId;

    // Fetch data and render
    fetchNetworkData(userId).then(data => {
        renderNetworkTree(data.nodes, data.root);
    });
}
```

## Data Structure

### Expected Data Format
```javascript
// Root user object
{
    user_id: "user123",
    username: "johndoe",
    child_count: 5,
    avatar_url: "https://example.com/avatar.jpg",
    profile_image_filename: "profile_123.jpg"
}

// Node data array
[
    {
        user_id: "user456",
        username: "childuser1",
        parent_id: "user123",
        child_count: 3,
        regist_time: "2024-01-15T10:30:00Z",
        avatar_url: "...",
        profile_image_filename: "..."
    },
    // ... more nodes
]
```

## Features

1. **Hierarchical View**: Shows parent → children (5 slots) → grandchildren (5 slots each)
2. **Avatar Display**: Shows user profile pictures with fallback to placeholder
3. **Child Count Badge**: Displays number of children on avatar
4. **Interactive Navigation**: Click any node to view their subtree
5. **Back Navigation**: Navigate back through tree history
6. **Empty Slot Indicators**: Shows available slots (up to 5 per parent)
7. **Responsive Grid**: Auto-adjusts to screen size
8. **Hover Effects**: Visual feedback on hover

## Integration Requirements

1. **Dependencies**:
   - Tailwind CSS
   - Font Awesome icons

2. **Global Variables**:
   ```javascript
   let navigationHistory = [];
   let currentTreeRoot = null;
   ```

3. **API Endpoints**:
   - `fetchNetworkData(userId)` - Fetch network tree data for specific user

4. **Event Handlers**:
   - `loadNetworkTree(userId)` - Load and render tree for user
   - `changeTreeRoot()` - Change root from selector
   - `navigateBack()` - Navigate to previous level

## Color Scheme

- **Background**: Dark gray (#1F2937, #111827)
- **Parent Cards**: Emerald accent (#10B981)
- **Child Cards**: Cyan accent (#06B6D4)
- **Empty Slots**: Dashed gray borders
- **Text**: White (#FFFFFF) primary, Gray (#9CA3AF) secondary

## Usage Example

```javascript
// Initialize tree
loadNetworkTree('root_user_id');

// Change root
document.getElementById('treeRootSelector').value = 'user123';
changeTreeRoot();

// Navigate back
navigateBack();
```

## Notes

- Maximum 5 children per parent (ACF 5×7 structure)
- Tree loads 2 levels deep (parent → children → grandchildren)
- Sorted by registration time (earliest first)
- Click any node to drill down into their network
- Back button appears when navigation history exists
