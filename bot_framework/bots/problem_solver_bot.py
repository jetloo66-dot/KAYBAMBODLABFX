"""Problem solver bot for analyzing and providing solutions to problems."""

from typing import Any, Dict, List, Optional
import re
import json
from ..core.base_bot import BaseBot


class ProblemSolverBot(BaseBot):
    """Bot that analyzes problems and provides structured solutions."""
    
    def __init__(self, name: Optional[str] = None, config: Optional[Dict[str, Any]] = None):
        """Initialize the problem solver bot.
        
        Args:
            name: Optional name for the bot
            config: Configuration dictionary
        """
        super().__init__(name, config)
        self.solution_strategies = [
            self._break_down_strategy,
            self._systematic_analysis_strategy,
            self._resource_identification_strategy,
            self._step_by_step_strategy
        ]
        
    def execute(self, problem: str) -> Dict[str, Any]:
        """Execute problem solving analysis.
        
        Args:
            problem: Problem description to solve
            
        Returns:
            Dictionary containing problem analysis and solution
        """
        return self.solve(problem)
        
    def solve(self, problem: str) -> Dict[str, Any]:
        """Analyze a problem and provide a structured solution.
        
        Args:
            problem: Problem description to solve
            
        Returns:
            Dictionary containing:
            - problem: Original problem statement
            - analysis: Problem analysis
            - solution: Structured solution
            - steps: Action steps
            - resources: Required resources
            - timeline: Estimated timeline
        """
        if not problem or not problem.strip():
            return {
                'error': 'No problem provided',
                'solution': 'Please provide a clear problem description'
            }
            
        # Analyze the problem
        analysis = self._analyze_problem(problem)
        
        # Generate solution using multiple strategies
        solution_components = {}
        for strategy in self.solution_strategies:
            strategy_result = strategy(problem, analysis)
            solution_components.update(strategy_result)
            
        # Compile final solution
        solution = {
            'problem': problem.strip(),
            'analysis': analysis,
            'solution': solution_components.get('main_solution', 'Analysis completed'),
            'steps': solution_components.get('steps', []),
            'resources': solution_components.get('resources', []),
            'timeline': solution_components.get('timeline', 'Variable'),
            'priority': solution_components.get('priority', 'Medium'),
            'complexity': solution_components.get('complexity', 'Medium'),
            'success_criteria': solution_components.get('success_criteria', [])
        }
        
        return solution
        
    def _analyze_problem(self, problem: str) -> Dict[str, Any]:
        """Analyze the problem to understand its nature.
        
        Args:
            problem: Problem description
            
        Returns:
            Problem analysis dictionary
        """
        problem_lower = problem.lower()
        
        # Identify problem type
        problem_type = 'general'
        if any(word in problem_lower for word in ['code', 'programming', 'bug', 'error', 'function']):
            problem_type = 'technical'
        elif any(word in problem_lower for word in ['business', 'process', 'workflow', 'efficiency']):
            problem_type = 'business'
        elif any(word in problem_lower for word in ['learn', 'understand', 'study', 'knowledge']):
            problem_type = 'educational'
        elif any(word in problem_lower for word in ['organize', 'manage', 'plan', 'schedule']):
            problem_type = 'organizational'
            
        # Identify urgency indicators
        urgency = 'medium'
        if any(word in problem_lower for word in ['urgent', 'asap', 'immediately', 'critical', 'emergency']):
            urgency = 'high'
        elif any(word in problem_lower for word in ['later', 'eventually', 'when possible', 'low priority']):
            urgency = 'low'
            
        # Identify complexity indicators
        complexity = 'medium'
        if any(word in problem_lower for word in ['simple', 'basic', 'easy', 'straightforward']):
            complexity = 'low'
        elif any(word in problem_lower for word in ['complex', 'complicated', 'advanced', 'difficult']):
            complexity = 'high'
            
        # Extract key entities (simple keyword extraction)
        keywords = re.findall(r'\b[a-zA-Z]{3,}\b', problem)
        keywords = [word.lower() for word in keywords if word.lower() not in 
                   ['the', 'and', 'or', 'but', 'for', 'with', 'this', 'that', 'have', 'need']]
        
        return {
            'type': problem_type,
            'urgency': urgency,
            'complexity': complexity,
            'keywords': list(set(keywords))[:10],  # Top 10 unique keywords
            'length': len(problem.split()),
            'questions_count': problem.count('?')
        }
        
    def _break_down_strategy(self, problem: str, analysis: Dict[str, Any]) -> Dict[str, Any]:
        """Break down the problem into smaller components.
        
        Args:
            problem: Problem description
            analysis: Problem analysis
            
        Returns:
            Strategy results
        """
        # Split problem into sentences
        sentences = [s.strip() for s in problem.split('.') if s.strip()]
        
        components = []
        for i, sentence in enumerate(sentences, 1):
            if sentence:
                components.append(f"Component {i}: {sentence}")
                
        return {
            'breakdown': components,
            'main_solution': f"Break down the problem into {len(components)} manageable components"
        }
        
    def _systematic_analysis_strategy(self, problem: str, analysis: Dict[str, Any]) -> Dict[str, Any]:
        """Apply systematic analysis to the problem.
        
        Args:
            problem: Problem description
            analysis: Problem analysis
            
        Returns:
            Strategy results
        """
        steps = [
            "Define the problem clearly",
            "Identify root causes",
            "Brainstorm potential solutions",
            "Evaluate solution options",
            "Implement the best solution",
            "Monitor and adjust as needed"
        ]
        
        if analysis['type'] == 'technical':
            steps.extend([
                "Review documentation and resources",
                "Test in a controlled environment",
                "Document the solution"
            ])
        elif analysis['type'] == 'business':
            steps.extend([
                "Assess business impact",
                "Consult with stakeholders",
                "Develop implementation plan"
            ])
            
        return {
            'steps': steps,
            'priority': analysis['urgency'].title()
        }
        
    def _resource_identification_strategy(self, problem: str, analysis: Dict[str, Any]) -> Dict[str, Any]:
        """Identify resources needed to solve the problem.
        
        Args:
            problem: Problem description
            analysis: Problem analysis
            
        Returns:
            Strategy results
        """
        resources = ["Time", "Information/Research"]
        
        if analysis['type'] == 'technical':
            resources.extend([
                "Development tools",
                "Testing environment",
                "Documentation",
                "Technical expertise"
            ])
        elif analysis['type'] == 'business':
            resources.extend([
                "Stakeholder input",
                "Budget allocation",
                "Process documentation",
                "Team coordination"
            ])
        elif analysis['type'] == 'educational':
            resources.extend([
                "Learning materials",
                "Practice opportunities",
                "Mentor/guidance",
                "Study time"
            ])
            
        return {
            'resources': resources,
            'complexity': analysis['complexity'].title()
        }
        
    def _step_by_step_strategy(self, problem: str, analysis: Dict[str, Any]) -> Dict[str, Any]:
        """Generate step-by-step solution approach.
        
        Args:
            problem: Problem description  
            analysis: Problem analysis
            
        Returns:
            Strategy results
        """
        timeline = "1-3 days"
        success_criteria = []
        
        if analysis['complexity'] == 'low':
            timeline = "Few hours"
            success_criteria = ["Problem resolved", "Solution tested"]
        elif analysis['complexity'] == 'high':
            timeline = "1-2 weeks"
            success_criteria = [
                "All components addressed",
                "Solution thoroughly tested",
                "Documentation completed",
                "Stakeholders satisfied"
            ]
        else:
            success_criteria = [
                "Problem resolved",
                "Solution implemented",
                "Results verified"
            ]
            
        if analysis['urgency'] == 'high':
            timeline = f"Urgent - {timeline}"
            
        return {
            'timeline': timeline,
            'success_criteria': success_criteria
        }