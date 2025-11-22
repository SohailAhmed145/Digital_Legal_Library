#!/usr/bin/env python3
"""
Script to fix all theme references in LaWise Flutter app
Replaces old theme properties with new Material 3 theme properties
"""

import os
import re
from pathlib import Path

# Old to new theme property mappings
THEME_MAPPINGS = {
    # Colors
    'AppTheme.textPrimaryColor': 'AppTheme.onSurfaceColor',
    'AppTheme.textSecondaryColor': 'AppTheme.onSurfaceColor.withOpacity(0.7)',
    'AppTheme.textTertiaryColor': 'AppTheme.onSurfaceColor.withOpacity(0.5)',
    'AppTheme.successColor': 'AppTheme.secondaryColor',
    'AppTheme.warningColor': 'AppTheme.errorColor',
    'AppTheme.infoColor': 'AppTheme.primaryColor',
    
    # Practice area colors
    'AppTheme.civilColor': 'AppTheme.secondaryColor.withOpacity(0.1)',
    'AppTheme.criminalColor': 'AppTheme.errorColor.withOpacity(0.1)',
    'AppTheme.corporateColor': 'AppTheme.primaryColor.withOpacity(0.1)',
    'AppTheme.familyColor': 'AppTheme.secondaryColor.withOpacity(0.1)',
    'AppTheme.propertyColor': 'AppTheme.primaryColor.withOpacity(0.1)',
    'AppTheme.taxColor': 'AppTheme.secondaryColor.withOpacity(0.1)',
    'AppTheme.probateColor': 'AppTheme.secondaryColor.withOpacity(0.1)',
    'AppTheme.ipColor': 'AppTheme.primaryColor.withOpacity(0.1)',
    'AppTheme.administrativeColor': 'AppTheme.secondaryColor.withOpacity(0.1)',
    
    # Text styles
    'AppTheme.logoStyle': 'AppTheme.headlineLarge',
    'AppTheme.taglineStyle': 'AppTheme.bodyMedium',
    'AppTheme.caseTitleStyle': 'AppTheme.cardTitle',
    'AppTheme.caseSubtitleStyle': 'AppTheme.cardSubtitle',
    'AppTheme.statusChipStyle': 'AppTheme.labelMedium',
    'AppTheme.timestampStyle': 'AppTheme.bodySmall',
}

def fix_file(file_path):
    """Fix theme references in a single file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Apply all theme mappings
        for old_prop, new_prop in THEME_MAPPINGS.items():
            content = content.replace(old_prop, new_prop)
        
        # If content changed, write it back
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ Fixed: {file_path}")
            return True
        else:
            print(f"⏭️  No changes: {file_path}")
            return False
            
    except Exception as e:
        print(f"❌ Error processing {file_path}: {e}")
        return False

def main():
    """Main function to process all Dart files"""
    # Get the project root directory
    project_root = Path.cwd()
    lib_dir = project_root / 'lib'
    
    if not lib_dir.exists():
        print("❌ lib directory not found. Make sure you're in the project root.")
        return
    
    print("🔧 Starting theme fix process...")
    print(f"📁 Project root: {project_root}")
    print(f"📁 Lib directory: {lib_dir}")
    print()
    
    # Find all Dart files
    dart_files = list(lib_dir.rglob('*.dart'))
    print(f"📊 Found {len(dart_files)} Dart files")
    print()
    
    # Process each file
    fixed_count = 0
    for dart_file in dart_files:
        if fix_file(dart_file):
            fixed_count += 1
    
    print()
    print(f"🎉 Theme fix complete!")
    print(f"📊 Files processed: {len(dart_files)}")
    print(f"🔧 Files fixed: {fixed_count}")
    print(f"⏭️  Files unchanged: {len(dart_files) - fixed_count}")

if __name__ == "__main__":
    main()
