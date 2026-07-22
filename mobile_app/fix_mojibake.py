import os

replacements = {
    'â€”': '—',
    'â€¢': '•',
    'âœ…': '✅',
    'â€¦': '…',
    'ðŸ‘‹': '👋',
    'ðŸ\"': '📞',
    'ðŸ''¤': '👤',
    'â—': '•',
    'â€': '—'
}

def fix_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        new_content = content
        for k, v in replacements.items():
            new_content = new_content.replace(k, v)
            
        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f'Fixed {filepath}')
    except Exception as e:
        print(f'Error on {filepath}: {e}')

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))
print('Done.')
