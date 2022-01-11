module realm.entitymanager;

public
{
	import realm.gameentity;
	import realm.ocean;
	import realm.world;
	import realm.player;
}
private
{
	import realm.engine.ecs;
}
class EntityManager
{
	mixin EntityRegistry!(World,GameEntity,Ocean,Player);

}