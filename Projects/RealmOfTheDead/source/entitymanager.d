module realmofthedead.entitymanager;


public
{
	import realmofthedead.gameentity;
	import realmofthedead.player;
}

private
{
	import realm.engine.ecs;
}
class EntityManager
{
	mixin EntityRegistry!(GameEntity,Player);	

}
