#!/usr/bin/env python3
import json
import sys
import os

# Load all quiz batches
all_quizzes = []

# Batch 1
if os.path.exists('quizzes_batch1_priority.json'):
    with open('quizzes_batch1_priority.json', 'r', encoding='utf-8') as f:
        batch1 = json.load(f)
        all_quizzes.extend(batch1['quizzes'])
        print(f"Loaded {len(batch1['quizzes'])} quizzes from batch 1")

# Batch 2
if os.path.exists('quizzes_batch2_cultural_nature.json'):
    with open('quizzes_batch2_cultural_nature.json', 'r', encoding='utf-8') as f:
        batch2 = json.load(f)
        all_quizzes.extend(batch2['quizzes'])
        print(f"Loaded {len(batch2['quizzes'])} quizzes from batch 2")

# Batch 3
if os.path.exists('quizzes_batch3_cultural_lakes.json'):
    with open('quizzes_batch3_cultural_lakes.json', 'r', encoding='utf-8') as f:
        batch3 = json.load(f)
        all_quizzes.extend(batch3['quizzes'])
        print(f"Loaded {len(batch3['quizzes'])} quizzes from batch 3")

# Batch 4
if os.path.exists('quizzes_batch4_theaters_culture.json'):
    with open('quizzes_batch4_theaters_culture.json', 'r', encoding='utf-8') as f:
        batch4 = json.load(f)
        all_quizzes.extend(batch4['quizzes'])
        print(f"Loaded {len(batch4['quizzes'])} quizzes from batch 4")

# Batch 5
if os.path.exists('quizzes_batch5_modern_culture.json'):
    with open('quizzes_batch5_modern_culture.json', 'r', encoding='utf-8') as f:
        batch5 = json.load(f)
        all_quizzes.extend(batch5['quizzes'])
        print(f"Loaded {len(batch5['quizzes'])} quizzes from batch 5")

# Batch 6
if os.path.exists('quizzes_batch6_entertainment_sports.json'):
    with open('quizzes_batch6_entertainment_sports.json', 'r', encoding='utf-8') as f:
        batch6 = json.load(f)
        all_quizzes.extend(batch6['quizzes'])
        print(f"Loaded {len(batch6['quizzes'])} quizzes from batch 6")

# Batch 7
if os.path.exists('quizzes_batch7_sports_entertainment.json'):
    with open('quizzes_batch7_sports_entertainment.json', 'r', encoding='utf-8') as f:
        batch7 = json.load(f)
        all_quizzes.extend(batch7['quizzes'])
        print(f"Loaded {len(batch7['quizzes'])} quizzes from batch 7")

# Load locations.json
with open('MunichQuest/MunichQuest/Resources/locations.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Group quizzes by location
quizzes_by_location = {}
for quiz in all_quizzes:
    loc_id = quiz['locationId']
    if loc_id not in quizzes_by_location:
        quizzes_by_location[loc_id] = []
    quizzes_by_location[loc_id].append(quiz)

# Add quizzes to the data
if 'quizzes' not in data:
    data['quizzes'] = {}

added_count = 0
for quiz in all_quizzes:
    quiz_id = quiz['id']
    if quiz_id not in data['quizzes']:
        data['quizzes'][quiz_id] = quiz
        added_count += 1
        print(f"Added quiz: {quiz_id}")

# Update location quizIds
for loc_id, quizzes in quizzes_by_location.items():
    if loc_id in data['locations']:
        if 'quizIds' not in data['locations'][loc_id]:
            data['locations'][loc_id]['quizIds'] = []

        for quiz in quizzes:
            quiz_id = quiz['id']
            if quiz_id not in data['locations'][loc_id]['quizIds']:
                data['locations'][loc_id]['quizIds'].append(quiz_id)
                print(f"Added {quiz_id} to {loc_id}")

# Save updated locations.json
with open('MunichQuest/MunichQuest/Resources/locations.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"\n✅ Added {added_count} quizzes")
print(f"✅ Updated {len(quizzes_by_location)} locations")
print("\nLocations updated:")
for loc_id, quizzes in quizzes_by_location.items():
    print(f"  - {loc_id}: {len(quizzes)} quizzes")
