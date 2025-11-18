"""Interactive bot template for custom interactive bots."""

from typing import Any, Dict, List, Optional, Callable
from ..core.base_bot import BaseBot


class InteractiveBot(BaseBot):
    """Template bot for creating custom interactive bots."""
    
    def __init__(self, name: Optional[str] = None, config: Optional[Dict[str, Any]] = None):
        """Initialize the interactive bot.
        
        Args:
            name: Optional name for the bot
            config: Configuration dictionary
        """
        super().__init__(name, config)
        self.conversation_history = []
        self.commands = {}
        self.context = {}
        
        # Register built-in commands
        self._register_builtin_commands()
        
    def execute(self, input_data: Any) -> Dict[str, Any]:
        """Execute interactive bot with user input.
        
        Args:
            input_data: User input (typically a string command or dict)
            
        Returns:
            Bot response
        """
        return self.interact(input_data)
        
    def interact(self, user_input: Any) -> Dict[str, Any]:
        """Process user interaction.
        
        Args:
            user_input: User input to process
            
        Returns:
            Response dictionary containing:
            - response: Bot response message
            - action: Action taken (if any)
            - context: Updated context
            - suggestions: Suggested next actions
        """
        if isinstance(user_input, str):
            user_input = user_input.strip()
        
        # Record interaction
        interaction = {
            'timestamp': self.last_execution or self.created_at,
            'user_input': user_input,
            'bot_response': None
        }
        
        try:
            response = self._process_input(user_input)
            interaction['bot_response'] = response
            self.conversation_history.append(interaction)
            
            return response
            
        except Exception as e:
            error_response = {
                'response': f"I encountered an error: {e}",
                'action': 'error',
                'context': self.context,
                'suggestions': ['help', 'status', 'reset']
            }
            interaction['bot_response'] = error_response
            self.conversation_history.append(interaction)
            
            return error_response
            
    def _process_input(self, user_input: Any) -> Dict[str, Any]:
        """Process user input and generate response.
        
        Args:
            user_input: User input to process
            
        Returns:
            Response dictionary
        """
        if not user_input:
            return {
                'response': "I didn't receive any input. How can I help you?",
                'action': 'prompt',
                'context': self.context,
                'suggestions': ['help', 'commands', 'status']
            }
            
        # Handle string commands
        if isinstance(user_input, str):
            command_parts = user_input.split()
            command = command_parts[0].lower()
            args = command_parts[1:] if len(command_parts) > 1 else []
            
            # Check for registered commands
            if command in self.commands:
                return self.commands[command](args)
            else:
                return self._handle_unknown_command(user_input, command, args)
                
        # Handle dict input
        elif isinstance(user_input, dict):
            return self._handle_dict_input(user_input)
            
        # Handle other input types
        else:
            return {
                'response': f"I received: {user_input}. I'm not sure how to process this type of input.",
                'action': 'unknown_input',
                'context': self.context,
                'suggestions': ['help', 'Use text commands or structured dict input']
            }
            
    def _handle_unknown_command(self, full_input: str, command: str, args: List[str]) -> Dict[str, Any]:
        """Handle unknown commands with helpful suggestions.
        
        Args:
            full_input: Original user input
            command: Parsed command
            args: Command arguments
            
        Returns:
            Response dictionary
        """
        # Try to find similar commands
        similar_commands = []
        for cmd in self.commands.keys():
            if command in cmd or cmd in command:
                similar_commands.append(cmd)
                
        response = f"I don't recognize the command '{command}'."
        suggestions = ['help', 'commands']
        
        if similar_commands:
            response += f" Did you mean: {', '.join(similar_commands)}?"
            suggestions.extend(similar_commands)
        else:
            response += " Type 'help' to see available commands."
            
        return {
            'response': response,
            'action': 'unknown_command',
            'context': self.context,
            'suggestions': suggestions
        }
        
    def _handle_dict_input(self, input_dict: Dict[str, Any]) -> Dict[str, Any]:
        """Handle dictionary input.
        
        Args:
            input_dict: Dictionary input
            
        Returns:
            Response dictionary
        """
        action = input_dict.get('action', 'unknown')
        data = input_dict.get('data', {})
        
        if action == 'set_context':
            self.context.update(data)
            return {
                'response': f"Updated context with {len(data)} items",
                'action': 'context_updated',
                'context': self.context,
                'suggestions': ['status', 'get_context']
            }
        elif action == 'get_context':
            return {
                'response': f"Current context: {self.context}",
                'action': 'context_retrieved',
                'context': self.context,
                'suggestions': ['set_context', 'clear_context']
            }
        elif action == 'execute_task':
            return self._execute_custom_task(data)
        else:
            return {
                'response': f"Unknown action: {action}",
                'action': 'unknown_action',
                'context': self.context,
                'suggestions': ['set_context', 'get_context', 'execute_task']
            }
            
    def _execute_custom_task(self, task_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a custom task.
        
        Args:
            task_data: Task data dictionary
            
        Returns:
            Task execution result
        """
        task_type = task_data.get('type', 'generic')
        
        # This is a template - implement custom task logic here
        result = f"Executed {task_type} task with data: {task_data}"
        
        return {
            'response': result,
            'action': 'task_executed',
            'context': self.context,
            'suggestions': ['status', 'history']
        }
        
    def register_command(self, command: str, handler: Callable[[List[str]], Dict[str, Any]]) -> None:
        """Register a custom command.
        
        Args:
            command: Command name
            handler: Function to handle the command
        """
        self.commands[command.lower()] = handler
        
    def _register_builtin_commands(self) -> None:
        """Register built-in commands."""
        self.register_command('help', self._cmd_help)
        self.register_command('commands', self._cmd_commands)
        self.register_command('status', self._cmd_status)
        self.register_command('history', self._cmd_history)
        self.register_command('clear', self._cmd_clear)
        self.register_command('reset', self._cmd_reset)
        self.register_command('context', self._cmd_context)
        
    def _cmd_help(self, args: List[str]) -> Dict[str, Any]:
        """Help command handler."""
        help_text = """
Interactive Bot Help:
- help: Show this help message
- commands: List all available commands  
- status: Show bot status and info
- history: Show conversation history
- clear: Clear conversation history
- reset: Reset bot context
- context: Show current context

You can also use structured input with dictionaries for advanced interactions.
        """.strip()
        
        return {
            'response': help_text,
            'action': 'help_shown',
            'context': self.context,
            'suggestions': ['commands', 'status']
        }
        
    def _cmd_commands(self, args: List[str]) -> Dict[str, Any]:
        """Commands list handler."""
        commands_list = list(self.commands.keys())
        
        return {
            'response': f"Available commands: {', '.join(commands_list)}",
            'action': 'commands_listed',
            'context': self.context,
            'suggestions': ['help'] + commands_list[:3]
        }
        
    def _cmd_status(self, args: List[str]) -> Dict[str, Any]:
        """Status command handler."""
        status_info = {
            'bot_name': self.name,
            'bot_id': self.id[:8],
            'active': self.active,
            'conversations': len(self.conversation_history),
            'context_items': len(self.context),
            'registered_commands': len(self.commands)
        }
        
        status_text = "\n".join([f"{k}: {v}" for k, v in status_info.items()])
        
        return {
            'response': f"Bot Status:\n{status_text}",
            'action': 'status_shown',
            'context': self.context,
            'suggestions': ['history', 'context', 'help']
        }
        
    def _cmd_history(self, args: List[str]) -> Dict[str, Any]:
        """History command handler."""
        history_count = len(self.conversation_history)
        limit = 5
        
        if args and args[0].isdigit():
            limit = min(int(args[0]), 20)  # Max 20 items
            
        recent_history = self.conversation_history[-limit:]
        
        history_text = f"Recent {len(recent_history)} of {history_count} interactions:\n"
        for i, interaction in enumerate(recent_history, 1):
            user_input = str(interaction['user_input'])
            if len(user_input) > 50:
                user_input = user_input[:47] + "..."
            history_text += f"{i}. User: {user_input}\n"
            
        return {
            'response': history_text.strip(),
            'action': 'history_shown',
            'context': self.context,
            'suggestions': ['clear', 'status']
        }
        
    def _cmd_clear(self, args: List[str]) -> Dict[str, Any]:
        """Clear history command handler."""
        cleared_count = len(self.conversation_history)
        self.conversation_history.clear()
        
        return {
            'response': f"Cleared {cleared_count} conversation history items",
            'action': 'history_cleared',
            'context': self.context,
            'suggestions': ['status', 'help']
        }
        
    def _cmd_reset(self, args: List[str]) -> Dict[str, Any]:
        """Reset bot command handler."""
        self.context.clear()
        self.conversation_history.clear()
        
        return {
            'response': "Bot context and history have been reset",
            'action': 'bot_reset',
            'context': self.context,
            'suggestions': ['help', 'status']
        }
        
    def _cmd_context(self, args: List[str]) -> Dict[str, Any]:
        """Context command handler."""
        if not self.context:
            return {
                'response': "Context is empty",
                'action': 'context_shown',
                'context': self.context,
                'suggestions': ['Use dict input to set context']
            }
            
        context_text = "Current context:\n"
        for key, value in self.context.items():
            value_str = str(value)
            if len(value_str) > 100:
                value_str = value_str[:97] + "..."
            context_text += f"  {key}: {value_str}\n"
            
        return {
            'response': context_text.strip(),
            'action': 'context_shown',
            'context': self.context,
            'suggestions': ['reset', 'status']
        }