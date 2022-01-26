module realm.entitymanager;

public
{
	import realm.gameentity;
	import realm.ocean;
	import realm.world;
	import realm.player;
	import realm.uimenu;
	import realm.fsm.statemachine;
	import realm.terraingeneration;
}
private
{
	import realm.engine.ecs;
}
class EntityManager
{
	mixin EntityRegistry!(World,GameEntity,Ocean,Player,UIMenu,StateMachine,TerrainGeneration);

}