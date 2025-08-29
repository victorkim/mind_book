#!/usr/bin/env python3
"""
Historical Conversation Parser for Agent Management Tool

Processes large Claude JSON export files and creates manageable CSV outputs
for conversation analysis and project classification.

Usage:
    python scripts/historical_parser.py

Input:
    - data/historical_export/conversations.json (38MB+)
    - data/historical_export/projects.json (600KB)

Output:
    - data/filtered_output/conversations_from_YYYY-MM-DD.csv
    - All messages from specified date onwards
"""

import json
import pandas as pd
import ijson
from datetime import datetime, timedelta
import os
import logging
from pathlib import Path

class HistoricalParser:
    def __init__(self):
        self.base_dir = Path(__file__).parent.parent
        self.export_dir = self.base_dir / "data" / "historical_export"
        self.output_dir = self.base_dir / "data" / "filtered_output"
        self.config_dir = self.base_dir / "config"
        self.logs_dir = self.base_dir / "logs"
        
        # DATE FILTERING - CHANGE THIS DATE AS NEEDED
        self.start_date = datetime(2025, 8, 26)  # August 26th, 2025
        
        # Ensure directories exist
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.logs_dir.mkdir(parents=True, exist_ok=True)
        
        # Setup logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(self.logs_dir / 'processing.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def parse_conversations_file(self):
        """Parse conversations.json and process all conversations"""
        conversations_file = self.export_dir / "conversations.json"
        
        if not conversations_file.exists():
            self.logger.error(f"Conversations file not found: {conversations_file}")
            return []
        
        filtered_conversations = []
        total_processed = 0
        
        self.logger.info(f"Processing conversations file: {conversations_file}")
        self.logger.info(f"File size: {conversations_file.stat().st_size / (1024*1024):.1f} MB")
        self.logger.info(f"Filtering messages from {self.start_date.strftime('%Y-%m-%d')} onwards")
        
        try:
            with open(conversations_file, 'rb') as file:
                # Stream parse the JSON to handle large files
                conversations = ijson.items(file, 'item')
                
                for conversation in conversations:
                    total_processed += 1
                    
                    if total_processed % 100 == 0:  # Progress indicator
                        self.logger.info(f"Processed {total_processed} conversations, found {len(filtered_conversations)} with recent messages...")
                    
                    processed_conv = self.process_single_conversation(conversation)
                    if processed_conv:
                        filtered_conversations.append(processed_conv)
        
        except Exception as e:
            self.logger.error(f"Error parsing conversations file: {e}")
            return []
        
        self.logger.info(f"Total conversations processed: {total_processed}")
        self.logger.info(f"Found {len(filtered_conversations)} conversations with messages from {self.start_date.strftime('%Y-%m-%d')} onwards")
        
        return filtered_conversations
    
    def process_single_conversation(self, conversation):
        """Extract and filter messages from specified date onwards"""
        try:
            # Basic metadata
            conv_id = conversation.get('uuid', 'unknown')
            created_at = conversation.get('created_at', '')
            updated_at = conversation.get('updated_at', '')
            name = conversation.get('name', 'Untitled')
            
            # Extract messages
            chat_messages = conversation.get('chat_messages', [])
            
            if not chat_messages:
                return None
            
            # Filter messages by date
            filtered_messages = []
            for message in chat_messages:
                msg_timestamp = message.get('created_at')
                if msg_timestamp:
                    try:
                        msg_date = datetime.fromisoformat(msg_timestamp.replace('Z', '+00:00'))
                        msg_date = msg_date.replace(tzinfo=None)
                        if msg_date >= self.start_date:
                            filtered_messages.append(message)
                    except:
                        continue
            
            # Skip conversations with no recent messages
            if not filtered_messages:
                return None
            
            self.logger.info(f"Found conversation with {len(filtered_messages)} recent messages: {conv_id}")
            
            # Process filtered messages only
            user_messages = []
            claude_responses = []
            total_chars = 0
            
            for message in filtered_messages:
                content = message.get('text', '')
                sender = message.get('sender', '')
                
                if sender == 'human':
                    user_messages.append(content)
                elif sender == 'assistant':
                    claude_responses.append(content)
                
                total_chars += len(content)
            
            # Create conversation text with filtered messages only
            conversation_text = f"=== CONVERSATION: {name} ===\n"
            conversation_text += f"Created: {created_at}\n"
            conversation_text += f"Updated: {updated_at}\n"
            conversation_text += f"Messages from: {self.start_date.strftime('%Y-%m-%d')} onwards\n\n"
            
            # Interleave filtered messages chronologically
            full_conversation = []
            for message in filtered_messages:
                sender = message.get('sender', 'unknown')
                content = message.get('text', '')
                timestamp = message.get('created_at', '')
                
                if sender == 'human':
                    full_conversation.append(f"USER [{timestamp}]:\n{content}\n")
                elif sender == 'assistant':
                    full_conversation.append(f"CLAUDE [{timestamp}]:\n{content}\n")
            
            conversation_text += "\n---\n".join(full_conversation)
            
            # Create preview
            conversation_preview = f"{name} | {len(user_messages)} user msgs, {len(claude_responses)} Claude responses (from {self.start_date.strftime('%Y-%m-%d')})"
            if user_messages:
                first_user_msg = user_messages[0][:200] + ("..." if len(user_messages[0]) > 200 else "")
                conversation_preview += f" | First message: {first_user_msg}"
            
            return {
                'conversation_id': conv_id,
                'date': created_at.split('T')[0] if 'T' in created_at else created_at,
                'updated_date': updated_at.split('T')[0] if 'T' in updated_at else updated_at,
                'title': name,
                'message_count': len(filtered_messages),
                'user_message_count': len(user_messages),
                'claude_response_count': len(claude_responses),
                'total_characters': total_chars,
                'conversation_preview': conversation_preview,
                'conversation_text': conversation_text
            }
        
        except Exception as e:
            self.logger.warning(f"Error processing conversation {conversation.get('uuid', 'unknown')}: {e}")
            return None
    
    def create_csv_chunks(self, conversations, max_size_mb=18):
        """Split conversations into CSV files under size limit"""
        if not conversations:
            self.logger.warning("No conversations to process")
            return
        
        # Sort by date
        conversations.sort(key=lambda x: x['date'])
        
        # Group into chunks by date ranges
        chunks = []
        current_chunk = []
        current_size = 0
        start_date = None
        
        for conv in conversations:
            if not start_date:
                start_date = conv['date']
            
            # Estimate size (rough calculation)
            conv_size = len(str(conv)) / (1024 * 1024)  # Convert to MB
            
            if current_size + conv_size > max_size_mb and current_chunk:
                # Save current chunk
                end_date = current_chunk[-1]['date']
                chunks.append({
                    'data': current_chunk.copy(),
                    'start_date': start_date,
                    'end_date': end_date
                })
                
                # Start new chunk
                current_chunk = [conv]
                current_size = conv_size
                start_date = conv['date']
            else:
                current_chunk.append(conv)
                current_size += conv_size
        
        # Add final chunk
        if current_chunk:
            end_date = current_chunk[-1]['date']
            chunks.append({
                'data': current_chunk,
                'start_date': start_date,
                'end_date': end_date
            })
        
        # Save chunks as CSV files
        for i, chunk in enumerate(chunks):
            if len(chunks) == 1:
                filename = "conversations.csv"
            else:
                filename = f"conversations_{chunk['start_date']}_to_{chunk['end_date']}.csv"
            filepath = self.output_dir / filename
            
            df = pd.DataFrame(chunk['data'])
            df.to_csv(filepath, index=False)
            
            file_size = filepath.stat().st_size / (1024 * 1024)
            self.logger.info(f"Created: {filename} ({file_size:.1f} MB, {len(chunk['data'])} conversations)")
    
    def load_projects_info(self):
        """Load and process projects.json for reference"""
        projects_file = self.export_dir / "projects.json"
        
        if not projects_file.exists():
            self.logger.warning(f"Projects file not found: {projects_file}")
            return {}
        
        try:
            with open(projects_file, 'r') as file:
                projects_data = json.load(file)
            
            self.logger.info(f"Loaded projects data: {len(projects_data)} projects")
            
            # Save simplified project mapping for reference
            project_mapping = {
                'total_projects': len(projects_data),
                'project_names': [p.get('name', 'Unnamed') for p in projects_data],
                'processed_date': datetime.now().isoformat(),
                'date_filter_from': self.start_date.isoformat(),
                'filtering_mode': 'message_filtered'
            }
            
            mapping_file = self.config_dir / "project_mapping.json"
            with open(mapping_file, 'w') as file:
                json.dump(project_mapping, file, indent=2)
            
            return projects_data
        
        except Exception as e:
            self.logger.error(f"Error loading projects file: {e}")
            return {}
    
    def run(self):
        """Main execution method - process messages from specified date"""
        self.logger.info("Starting message-filtered conversation processing...")
        self.logger.info(f"Target date: {self.start_date.strftime('%Y-%m-%d')} onwards")
        
        # Load projects info
        projects = self.load_projects_info()
        
        # Parse conversations and filter messages
        conversations = self.parse_conversations_file()
        
        if not conversations:
            self.logger.error("No conversations found with messages from the specified date")
            self.logger.info(f"Check that you have messages from {self.start_date.strftime('%Y-%m-%d')} onwards in your JSON file")
            return
        
        # Create CSV outputs
        self.create_csv_chunks(conversations)
        
        # Summary
        total_files = len(list(self.output_dir.glob("conversations*.csv")))
        self.logger.info(f"Processing complete! Created {total_files} CSV files in {self.output_dir}")
        self.logger.info("Next step: Upload CSV files to Claude for analysis and project classification")

if __name__ == "__main__":
    parser = HistoricalParser()
    parser.run()