"""Task automation bot for automating repetitive tasks."""

from typing import Any, Dict, List, Optional, Callable
import time
import json
from datetime import datetime, timedelta
from ..core.base_bot import BaseBot


class TaskAutomationBot(BaseBot):
    """Bot that automates repetitive tasks and workflows."""
    
    def __init__(self, name: Optional[str] = None, config: Optional[Dict[str, Any]] = None):
        """Initialize the task automation bot.
        
        Args:
            name: Optional name for the bot
            config: Configuration dictionary
        """
        super().__init__(name, config)
        self.tasks = []
        self.scheduled_tasks = []
        self.task_history = []
        
    def execute(self, task_definition: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a task automation workflow.
        
        Args:
            task_definition: Dictionary defining the task to automate
            
        Returns:
            Task execution result
        """
        return self.run_task(task_definition)
        
    def add_task(self, task_definition: Dict[str, Any]) -> str:
        """Add a new task to the automation bot.
        
        Args:
            task_definition: Dictionary containing:
                - name: Task name
                - type: Task type (file, web, data, system)
                - actions: List of actions to perform
                - schedule: Optional schedule information
                - conditions: Optional conditions for execution
                
        Returns:
            Task ID
        """
        task_id = f"task_{len(self.tasks) + 1}_{int(time.time())}"
        
        task = {
            'id': task_id,
            'name': task_definition.get('name', f'Task_{task_id}'),
            'type': task_definition.get('type', 'general'),
            'actions': task_definition.get('actions', []),
            'schedule': task_definition.get('schedule'),
            'conditions': task_definition.get('conditions', {}),
            'created_at': datetime.now(),
            'enabled': True,
            'execution_count': 0,
            'last_execution': None,
            'last_result': None
        }
        
        self.tasks.append(task)
        
        # If task has a schedule, add to scheduled tasks
        if task['schedule']:
            self._schedule_task(task)
            
        return task_id
        
    def run_task(self, task_definition: Dict[str, Any]) -> Dict[str, Any]:
        """Run a single task.
        
        Args:
            task_definition: Task definition or task ID
            
        Returns:
            Task execution result
        """
        if isinstance(task_definition, str):
            # It's a task ID
            task = self.get_task(task_definition)
            if not task:
                return {'error': f'Task not found: {task_definition}'}
        else:
            # It's a task definition
            task = task_definition
            
        if not task.get('enabled', True):
            return {'error': 'Task is disabled', 'task': task.get('name', 'Unknown')}
            
        # Check conditions
        if not self._check_conditions(task.get('conditions', {})):
            return {'skipped': True, 'reason': 'Conditions not met', 'task': task.get('name', 'Unknown')}
            
        start_time = datetime.now()
        results = []
        
        try:
            actions = task.get('actions', [])
            
            for i, action in enumerate(actions):
                action_result = self._execute_action(action)
                results.append({
                    'action_index': i,
                    'action': action,
                    'result': action_result,
                    'success': action_result.get('success', True)
                })
                
                # Stop if action failed and halt_on_error is set
                if not action_result.get('success', True) and action.get('halt_on_error', False):
                    break
                    
            end_time = datetime.now()
            duration = (end_time - start_time).total_seconds()
            
            # Update task history
            task_result = {
                'task_id': task.get('id'),
                'task_name': task.get('name', 'Unknown'),
                'start_time': start_time,
                'end_time': end_time,
                'duration_seconds': duration,
                'actions_executed': len(results),
                'actions_successful': sum(1 for r in results if r['success']),
                'results': results,
                'success': all(r['success'] for r in results)
            }
            
            # Update task if it's a stored task
            if 'id' in task:
                stored_task = self.get_task(task['id'])
                if stored_task:
                    stored_task['execution_count'] += 1
                    stored_task['last_execution'] = end_time
                    stored_task['last_result'] = task_result
                    
            self.task_history.append(task_result)
            return task_result
            
        except Exception as e:
            error_result = {
                'task_id': task.get('id'),
                'task_name': task.get('name', 'Unknown'),
                'error': str(e),
                'start_time': start_time,
                'end_time': datetime.now(),
                'success': False
            }
            self.task_history.append(error_result)
            return error_result
            
    def _execute_action(self, action: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a single action.
        
        Args:
            action: Action definition
            
        Returns:
            Action execution result
        """
        action_type = action.get('type', 'unknown')
        
        if action_type == 'wait':
            return self._action_wait(action)
        elif action_type == 'log':
            return self._action_log(action)
        elif action_type == 'file_operation':
            return self._action_file_operation(action)
        elif action_type == 'data_processing':
            return self._action_data_processing(action)
        elif action_type == 'system_command':
            return self._action_system_command(action)
        else:
            return {
                'success': False,
                'error': f'Unknown action type: {action_type}',
                'action': action
            }
            
    def _action_wait(self, action: Dict[str, Any]) -> Dict[str, Any]:
        """Execute wait action.
        
        Args:
            action: Wait action definition
            
        Returns:
            Action result
        """
        duration = action.get('duration', 1)
        time.sleep(duration)
        return {
            'success': True,
            'message': f'Waited for {duration} seconds',
            'duration': duration
        }
        
    def _action_log(self, action: Dict[str, Any]) -> Dict[str, Any]:
        """Execute log action.
        
        Args:
            action: Log action definition
            
        Returns:
            Action result
        """
        message = action.get('message', 'Task executed')
        level = action.get('level', 'info')
        
        print(f"[{level.upper()}] {message}")
        
        return {
            'success': True,
            'message': f'Logged message: {message}',
            'level': level
        }
        
    def _action_file_operation(self, action: Dict[str, Any]) -> Dict[str, Any]:
        """Execute file operation action.
        
        Args:
            action: File operation action definition
            
        Returns:
            Action result
        """
        operation = action.get('operation', 'read')
        file_path = action.get('file_path', '')
        
        try:
            if operation == 'read':
                with open(file_path, 'r') as f:
                    content = f.read()
                return {
                    'success': True,
                    'message': f'Read file: {file_path}',
                    'content_length': len(content)
                }
            elif operation == 'write':
                content = action.get('content', '')
                with open(file_path, 'w') as f:
                    f.write(content)
                return {
                    'success': True,
                    'message': f'Wrote to file: {file_path}',
                    'content_length': len(content)
                }
            else:
                return {
                    'success': False,
                    'error': f'Unknown file operation: {operation}'
                }
        except Exception as e:
            return {
                'success': False,
                'error': f'File operation failed: {e}'
            }
            
    def _action_data_processing(self, action: Dict[str, Any]) -> Dict[str, Any]:
        """Execute data processing action.
        
        Args:
            action: Data processing action definition
            
        Returns:
            Action result
        """
        operation = action.get('operation', 'transform')
        data = action.get('data', [])
        
        try:
            if operation == 'filter':
                condition = action.get('condition', lambda x: True)
                result = [item for item in data if condition(item)]
                return {
                    'success': True,
                    'message': f'Filtered {len(data)} items to {len(result)}',
                    'result_count': len(result)
                }
            elif operation == 'transform':
                transformer = action.get('transformer', lambda x: x)
                result = [transformer(item) for item in data]
                return {
                    'success': True,
                    'message': f'Transformed {len(data)} items',
                    'result_count': len(result)
                }
            else:
                return {
                    'success': False,
                    'error': f'Unknown data operation: {operation}'
                }
        except Exception as e:
            return {
                'success': False,
                'error': f'Data processing failed: {e}'
            }
            
    def _action_system_command(self, action: Dict[str, Any]) -> Dict[str, Any]:
        """Execute system command action.
        
        Args:
            action: System command action definition
            
        Returns:
            Action result
        """
        # For security, only allow safe commands
        safe_commands = ['echo', 'date', 'pwd', 'ls']
        command = action.get('command', '')
        
        if not any(command.startswith(safe_cmd) for safe_cmd in safe_commands):
            return {
                'success': False,
                'error': f'Command not allowed: {command}'
            }
            
        return {
            'success': True,
            'message': f'System command simulated: {command}',
            'command': command
        }
        
    def _check_conditions(self, conditions: Dict[str, Any]) -> bool:
        """Check if task conditions are met.
        
        Args:
            conditions: Conditions dictionary
            
        Returns:
            True if all conditions are met
        """
        if not conditions:
            return True
            
        # Check time-based conditions
        if 'time_range' in conditions:
            time_range = conditions['time_range']
            current_time = datetime.now().time()
            start_time = datetime.strptime(time_range['start'], '%H:%M').time()
            end_time = datetime.strptime(time_range['end'], '%H:%M').time()
            
            if not (start_time <= current_time <= end_time):
                return False
                
        # Check day-based conditions
        if 'days' in conditions:
            allowed_days = conditions['days']
            current_day = datetime.now().strftime('%A').lower()
            if current_day not in [day.lower() for day in allowed_days]:
                return False
                
        return True
        
    def _schedule_task(self, task: Dict[str, Any]) -> None:
        """Schedule a task for future execution.
        
        Args:
            task: Task definition
        """
        schedule = task.get('schedule', {})
        
        if 'interval' in schedule:
            # Recurring task
            next_run = datetime.now() + timedelta(seconds=schedule['interval'])
            self.scheduled_tasks.append({
                'task_id': task['id'],
                'next_run': next_run,
                'interval': schedule['interval'],
                'recurring': True
            })
        elif 'at' in schedule:
            # One-time scheduled task
            scheduled_time = datetime.fromisoformat(schedule['at'])
            self.scheduled_tasks.append({
                'task_id': task['id'],
                'next_run': scheduled_time,
                'recurring': False
            })
            
    def get_task(self, task_id: str) -> Optional[Dict[str, Any]]:
        """Get a task by ID.
        
        Args:
            task_id: Task identifier
            
        Returns:
            Task definition or None if not found
        """
        for task in self.tasks:
            if task['id'] == task_id:
                return task
        return None
        
    def list_tasks(self) -> List[Dict[str, Any]]:
        """List all tasks.
        
        Returns:
            List of task definitions
        """
        return self.tasks.copy()
        
    def get_task_history(self) -> List[Dict[str, Any]]:
        """Get task execution history.
        
        Returns:
            List of task execution results
        """
        return self.task_history.copy()