
from py4godot.methods import private
from py4godot.signals import signal, SignalArg
from py4godot.classes import gdclass
from py4godot.classes.core import Vector3
from py4godot.classes.Node import Node

@gdclass 
class suspect(Node):
	aggression: int #ranges: 0-100, determines how aggressive the responses are by the suspect.
	compliance: int #ranges: 0-100, determines which truths are revealed depending on how high it is
	stubborness : float #ranges: 0-1.0, determines how much the aggression and compliance can change (higher stubborness = being less convinced -> the harder compliance moves 
	list_of_truths: dict #list of truths that the suspect knows 
	list_of_lies: dict #list of lies that the suspect can tell when questioned and compliance is low
	
	def _ready(self) -> None:
		aggression = 0
		compliance = 0
		stubborness = 0
		list_of_truths = {}
		list_of_lies = {}
	
	# constructor
	def suspect(self, a: int, c:int, s:float, lt: dict, ll: dict):
		self.aggression = a
		self.compliance = c
		self.stubborness = s
		self.list_of_truths = lt
		self.list_of_lies = ll
		
	#setters
	def setAggression(self, aggression) -> None:
		self.aggression = aggression
		
	def setCompliance(self, compliance) -> None:
		self.compliance = compliance
	
	#getting both aggression and compliance as a Tuple
	def getAggressionCompliance(self):
		return (self.aggression, self.compliance)
		
		
		
	
	
