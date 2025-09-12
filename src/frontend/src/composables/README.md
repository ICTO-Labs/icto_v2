# useUniqueId Composable

## Description
The `useUniqueId` composable is created to solve the problem of duplicate IDs in form elements, especially checkboxes and labels. When multiple components use the same ID, clicking on a label will jump to the first element with that ID.

## Usage

### 1. Import composable
```typescript
import { useUniqueId } from '@/composables/useUniqueId'
```

### 2. Create unique ID for a single element
```typescript
const checkboxId = useUniqueId('checkbox')
// Result: "checkbox-1-1703123456789"
```

### 3. Create multiple unique IDs at once
```typescript
const ids = useUniqueIds(['checkbox1', 'checkbox2', 'input1'])
// Result: {
//   checkbox1: "checkbox1-1-1703123456789",
//   checkbox2: "checkbox2-2-1703123456790", 
//   input1: "input1-3-1703123456791"
// }
```

### 4. Create ID for component instance
```typescript
const componentId = useComponentId('MyComponent', 'instance-1')
// Result: "MyComponent-instance-1-4-1703123456792"
```

## Real-world Examples

### Before using (with duplicate ID problem)
```vue
<template>
  <div>
    <input id="enable-feature" type="checkbox" v-model="enabled" />
    <label for="enable-feature">Enable Feature</label>
  </div>
</template>
```

### After using (with unique ID)
```vue
<template>
  <div>
    <input :id="checkboxId" type="checkbox" v-model="enabled" />
    <label :for="checkboxId">Enable Feature</label>
  </div>
</template>

<script setup>
import { useUniqueId } from '@/composables/useUniqueId'

const checkboxId = useUniqueId('enable-feature')
</script>
```

## Benefits

1. **Avoid ID conflicts**: Each component instance has a unique ID
2. **Better accessibility**: Labels and inputs are properly linked
3. **Easy debugging**: IDs have prefix and timestamp to identify components
4. **Auto-increment**: Counter automatically increments for each new ID
5. **Flexible**: Can create IDs for multiple elements at once

## Notes

- IDs are created once when component mounts and don't change
- Each call to `useUniqueId()` creates a new ID
- Use `useUniqueIds()` when you need to create multiple IDs at once
- ID format: `{prefix}-{counter}-{timestamp}`
